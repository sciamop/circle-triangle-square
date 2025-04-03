import os
import torch
import numpy as np
from diffusers import StableDiffusionPipeline, DDPMScheduler
from diffusers.optimization import get_scheduler
from datasets import load_dataset
from torch.utils.data import DataLoader
from torchvision import transforms
from tqdm.auto import tqdm
from transformers import get_scheduler
import torch.nn.functional as F
from accelerate import Accelerator
from huggingface_hub import HfFolder, Repository, whoami
from pathlib import Path
import logging
import math
import argparse
from transformers import CLIPTokenizer, CLIPTextModel
from diffusers import AutoencoderKL, UNet2DConditionModel
from safetensors.torch import save_file

# Set up logging
logging.basicConfig(
    format="%(asctime)s - %(levelname)s - %(name)s - %(message)s",
    datefmt="%m/%d/%Y %H:%M:%S",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)

def parse_args():
    parser = argparse.ArgumentParser(description="Train Stable Diffusion model")
    parser.add_argument(
        "--pretrained_model_name_or_path",
        type=str,
        default="runwayml/stable-diffusion-v1-5",
        help="Path to pretrained model or model identifier from huggingface.co/models. Can be a local directory containing the model files.",
    )
    parser.add_argument(
        "--local_model_path",
        type=str,
        default=None,
        help="Path to local directory containing the base model files. If provided, this will be used instead of downloading from Hugging Face.",
    )
    parser.add_argument(
        "--resume_from_checkpoint",
        type=str,
        default=None,
        help="Whether training should be resumed from a previous checkpoint. Can either be `latest` to resume from the last available checkpoint or a path to a specific checkpoint.",
    )
    parser.add_argument(
        "--dataset_name",
        type=str,
        default=None,
        help="Name of the dataset (from the Hugging Face hub) to train on.",
    )
    parser.add_argument(
        "--dataset_config_name",
        type=str,
        default=None,
        help="The config of the dataset, leave as None if there's only one config.",
    )
    parser.add_argument(
        "--train_data_dir",
        type=str,
        default=None,
        help="A folder containing the training data.",
    )
    parser.add_argument(
        "--output_dir",
        type=str,
        default="sd-model-output",
        help="The output directory where the model predictions and checkpoints will be written.",
    )
    parser.add_argument(
        "--cache_dir",
        type=str,
        default=None,
        help="The directory where the downloaded models and datasets will be stored.",
    )
    parser.add_argument(
        "--resolution",
        type=int,
        default=512,
        help="The resolution for input images, all the images in the train/validation dataset will be resized to this resolution.",
    )
    parser.add_argument(
        "--train_batch_size",
        type=int,
        default=1,
        help="Batch size (per device) for the training dataloader.",
    )
    parser.add_argument(
        "--gradient_accumulation_steps",
        type=int,
        default=4,
        help="Number of updates steps to accumulate before performing a backward/update pass.",
    )
    parser.add_argument(
        "--learning_rate",
        type=float,
        default=1e-6,
        help="Initial learning rate (after the potential warmup period) to use.",
    )
    parser.add_argument(
        "--lr_scheduler",
        type=str,
        default="constant",
        help='The scheduler type to use. Choose between ["linear", "cosine", "cosine_with_restarts", "polynomial", "constant", "constant_with_warmup"]',
    )
    parser.add_argument(
        "--lr_warmup_steps",
        type=int,
        default=0,
        help="Number of steps for the warmup in the lr scheduler.",
    )
    parser.add_argument(
        "--max_train_steps",
        type=int,
        default=None,
        help="Total number of training steps to perform. If provided, overrides num_train_epochs.",
    )
    parser.add_argument(
        "--gradient_checkpointing",
        action="store_true",
        help="Whether or not to use gradient checkpointing to save memory at the expense of slower backward pass.",
    )
    parser.add_argument(
        "--mixed_precision",
        type=str,
        default=None,
        choices=["no", "fp16", "bf16"],
        help="Whether to use mixed precision. Choose between fp16 and bf16 (bfloat16).",
    )
    parser.add_argument(
        "--save_steps",
        type=int,
        default=500,
        help="Save checkpoint every X updates steps.",
    )
    parser.add_argument(
        "--logging_steps",
        type=int,
        default=10,
        help="Log training stats every X updates steps.",
    )
    parser.add_argument(
        "--logging_dir",
        type=str,
        default="logs",
        help="Directory to store logs for TensorBoard.",
    )
    parser.add_argument(
        "--max_grad_norm",
        type=float,
        default=1.0,
        help="Max gradient norm for gradient clipping.",
    )
    parser.add_argument(
        "--trigger_token",
        type=str,
        default="<my-trigger>",
        help="The trigger token to use for this model. This will be the word that activates the model's style.",
    )
    return parser.parse_args()

def get_full_repo_name(model_id: str, organization: str = None, token: str = None):
    if token is None:
        token = HfFolder.get_token()
    if organization is None:
        username = whoami(token)["name"]
        return f"{username}/{model_id}"
    else:
        return f"{organization}/{model_id}"

def main():
    args = parse_args()
    
    # Initialize accelerator
    accelerator = Accelerator(
        gradient_accumulation_steps=args.gradient_accumulation_steps,
        mixed_precision=args.mixed_precision,
        log_with=None,
    )

    # Determine which path to use for loading the model
    model_path = args.local_model_path if args.local_model_path else args.pretrained_model_name_or_path
    
    # Load models and create optimizer
    text_encoder = CLIPTextModel.from_pretrained(
        model_path,
        subfolder="text_encoder",
        local_files_only=bool(args.local_model_path),
    )
    
    # Load the tokenizer and add the placeholder token as a additional special token
    tokenizer = CLIPTokenizer.from_pretrained(
        model_path,
        subfolder="tokenizer",
        local_files_only=bool(args.local_model_path),
    )
    
    # Add custom trigger token
    num_added_tokens = tokenizer.add_tokens(args.trigger_token)
    token_ids = tokenizer.encode(args.trigger_token, add_special_tokens=False)
    # Resize the token embeddings as we are adding new special tokens to the tokenizer
    text_encoder.resize_token_embeddings(len(tokenizer))

    # Initialize the new token's embedding
    token_embeds = text_encoder.get_input_embeddings().weight.data
    # Initialize the new token's embedding with the average of all other embeddings
    token_embeds[-num_added_tokens:] = token_embeds[:-num_added_tokens].mean(dim=0)

    vae = AutoencoderKL.from_pretrained(
        model_path,
        subfolder="vae",
        local_files_only=bool(args.local_model_path),
    )
    unet = UNet2DConditionModel.from_pretrained(
        model_path,
        subfolder="unet",
        local_files_only=bool(args.local_model_path),
    )

    # Initialize the noise scheduler
    noise_scheduler = DDPMScheduler.from_pretrained(
        model_path,
        subfolder="scheduler",
        local_files_only=bool(args.local_model_path),
    )

    # Move models to device
    device = accelerator.device
    text_encoder = text_encoder.to(device)
    vae = vae.to(device)
    unet = unet.to(device)

    # Freeze vae and text_encoder
    vae.requires_grad_(False)
    text_encoder.requires_grad_(False)

    # Create optimizer
    optimizer = torch.optim.AdamW(
        unet.parameters(),
        lr=args.learning_rate,
        betas=(0.9, 0.999),
        weight_decay=1e-2,
    )

    # Load the dataset
    if args.dataset_name is not None:
        dataset = load_dataset(
            args.dataset_name,
            args.dataset_config_name,
            cache_dir=args.cache_dir,
        )
    else:
        dataset = load_dataset("imagefolder", data_dir=args.train_data_dir, cache_dir=args.cache_dir)

    # Preprocessing the datasets
    def transforms(examples):
        images = [image.convert("RGB") for image in examples["image"]]
        images = [image.resize((args.resolution, args.resolution)) for image in images]
        images = [np.array(image) for image in images]
        images = [image / 127.5 - 1 for image in images]
        images = [image.astype(np.float32) for image in images]  # Ensure float32 type
        
        # Reshape images to [batch_size, channels, height, width]
        images = [np.transpose(image, (2, 0, 1)) for image in images]
        
        # Create empty text prompts if no text is provided
        if "text" not in examples:
            examples["text"] = [""] * len(images)
            
        # Add trigger token to all prompts
        examples["text"] = [f"{args.trigger_token} {text}" for text in examples["text"]]
            
        inputs = tokenizer(
            examples["text"],
            max_length=tokenizer.model_max_length,
            padding="max_length",
            truncation=True,
        )
        # Convert input_ids to tensor
        input_ids = torch.tensor(inputs.input_ids)
        return {"input_ids": input_ids, "pixel_values": images}

    # Set the training transforms
    train_dataset = dataset["train"].with_transform(transforms)

    # Create the dataloader
    train_dataloader = DataLoader(
        train_dataset,
        batch_size=args.train_batch_size,
        shuffle=True,
    )

    # Prepare everything with accelerator
    unet, optimizer, train_dataloader = accelerator.prepare(
        unet, optimizer, train_dataloader
    )

    # Calculate number of training epochs
    num_update_steps_per_epoch = math.ceil(len(train_dataloader) / args.gradient_accumulation_steps)
    if args.max_train_steps is None:
        args.max_train_steps = args.num_train_epochs * num_update_steps_per_epoch
    args.num_train_epochs = math.ceil(args.max_train_steps / num_update_steps_per_epoch)

    # Create the learning rate scheduler
    lr_scheduler = get_scheduler(
        args.lr_scheduler,
        optimizer=optimizer,
        num_warmup_steps=args.lr_warmup_steps,
        num_training_steps=args.max_train_steps,
    )

    # Train!
    total_batch_size = args.train_batch_size * accelerator.num_processes * args.gradient_accumulation_steps
    logger.info("***** Running training *****")
    logger.info(f"  Num examples = {len(train_dataset)}")
    logger.info(f"  Num Epochs = {args.num_train_epochs}")
    logger.info(f"  Instantaneous batch size per device = {args.train_batch_size}")
    logger.info(f"  Gradient Accumulation steps = {args.gradient_accumulation_steps}")
    logger.info(f"  Total optimization steps = {args.max_train_steps}")
    logger.info(f"  Total batch size = {total_batch_size}")

    global_step = 0
    first_epoch = 0

    # Potentially load in the weights and states from a previous save
    if args.resume_from_checkpoint:
        if args.resume_from_checkpoint != "latest":
            path = os.path.basename(args.resume_from_checkpoint)
        else:
            # Get the most recent checkpoint
            dirs = os.listdir(args.output_dir)
            dirs = [d for d in dirs if d.startswith("checkpoint")]
            dirs = sorted(dirs, key=lambda x: int(x.split("-")[1]))
            path = dirs[-1] if len(dirs) > 0 else None

        if path is None:
            accelerator.print(
                f"Checkpoint '{args.resume_from_checkpoint}' does not exist. Starting a new training run."
            )
            args.resume_from_checkpoint = None
        else:
            accelerator.print(f"Resuming from checkpoint {path}")
            accelerator.load_state(os.path.join(args.output_dir, path))
            global_step = int(path.split("-")[1])

            resume_global_step = global_step * args.gradient_accumulation_steps
            first_epoch = global_step // num_update_steps_per_epoch
            resume_step = resume_global_step % (num_update_steps_per_epoch * args.gradient_accumulation_steps)

    # Only show the progress bar once on each machine
    progress_bar = tqdm(range(global_step, args.max_train_steps), disable=not accelerator.is_local_main_process)
    progress_bar.set_description("Steps")

    for epoch in range(first_epoch, args.num_train_epochs):
        unet.train()
        total_loss = 0
        for step, batch in enumerate(train_dataloader):
            # Skip steps until we reach the resumed step
            if args.resume_from_checkpoint and epoch == first_epoch and step < resume_step:
                if step % args.gradient_accumulation_steps == 0:
                    progress_bar.update(1)
                continue

            with accelerator.accumulate(unet):
                # Convert images to latent space
                latents = vae.encode(batch["pixel_values"]).latent_dist.sample()
                latents = latents * 0.18215

                # Sample noise that we'll add to the latents
                noise = torch.randn_like(latents)
                bsz = latents.shape[0]
                # Sample a random timestep for each image
                timesteps = torch.randint(0, noise_scheduler.config.num_train_timesteps, (bsz,), device=latents.device).long()

                # Add noise to the clean latents according to the noise magnitude at each timestep
                noisy_latents = noise_scheduler.add_noise(latents, noise, timesteps)

                # Get the text embedding for conditioning
                encoder_hidden_states = text_encoder(batch["input_ids"])[0]

                # Predict the noise residual
                noise_pred = unet(noisy_latents, timesteps, encoder_hidden_states).sample

                loss = F.mse_loss(noise_pred, noise, reduction="none").mean([1, 2, 3]).mean()
                accelerator.backward(loss)
                if accelerator.sync_gradients:
                    accelerator.clip_grad_norm_(unet.parameters(), args.max_grad_norm)
                optimizer.step()
                lr_scheduler.step()
                optimizer.zero_grad()

            # Checks if the accelerator has performed an optimization step behind the scenes
            if accelerator.sync_gradients:
                progress_bar.update(1)
                global_step += 1

                if global_step % args.save_steps == 0:
                    if accelerator.is_main_process:
                        # Generate validation images
                        pipeline = StableDiffusionPipeline.from_pretrained(
                            args.pretrained_model_name_or_path,
                            unet=accelerator.unwrap_model(unet),
                            text_encoder=text_encoder,
                            vae=vae,
                            tokenizer=tokenizer,
                            scheduler=noise_scheduler,
                        )
                        pipeline = pipeline.to(device)
                        
                        # Generate a few test images
                        test_prompts = [
                            f"{args.trigger_token} a beautiful sunset",
                            f"{args.trigger_token} a cute cat",
                            f"{args.trigger_token} a futuristic city"
                        ]
                        
                        for prompt in test_prompts:
                            image = pipeline(prompt, num_inference_steps=50).images[0]
                            image.save(os.path.join(args.output_dir, f"validation_{global_step}_{prompt[:20]}.png"))
                        
                        # Save checkpoint
                        pipeline.save_pretrained(args.output_dir)

            logs = {"loss": loss.detach().item(), "lr": lr_scheduler.get_last_lr()[0]}
            progress_bar.set_postfix(**logs)
            accelerator.log(logs, step=global_step)

            if global_step >= args.max_train_steps:
                break

    # Create the pipeline using the trained modules and save it
    accelerator.wait_for_everyone()
    if accelerator.is_main_process:
        pipeline = StableDiffusionPipeline.from_pretrained(
            args.pretrained_model_name_or_path,
            unet=accelerator.unwrap_model(unet),
            text_encoder=text_encoder,
            vae=vae,
            tokenizer=tokenizer,
            scheduler=noise_scheduler,
        )
        
        # Ensure output directory exists
        os.makedirs(args.output_dir, exist_ok=True)
        
        # Save in both formats
        # 1. Save as a full pipeline (for diffusers)
        pipeline.save_pretrained(args.output_dir)
        
        # 2. Save as a .ckpt file (for Automatic1111)
        ckpt_path = os.path.join(args.output_dir, "model.ckpt")
        ckpt_path = os.path.abspath(ckpt_path)  # Get absolute path
        
        # Convert to .ckpt format
        state_dict = {}
        state_dict.update(pipeline.unet.state_dict())
        state_dict.update(pipeline.text_encoder.state_dict())
        state_dict.update(pipeline.vae.state_dict())
        
        # Save using torch.save instead of safetensors
        torch.save(state_dict, ckpt_path)
        
        # Save trigger token info
        trigger_token_path = os.path.join(args.output_dir, "trigger_token.txt")
        with open(trigger_token_path, "w") as f:
            f.write(args.trigger_token)
            
        print(f"Model saved to {args.output_dir}")
        print(f"Trigger token: {args.trigger_token}")
        print(f"To use in Automatic1111, place the model.ckpt file in the models/Stable-diffusion folder")
    accelerator.end_training()

if __name__ == "__main__":
    main() 