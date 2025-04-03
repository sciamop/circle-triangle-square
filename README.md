# Stable Diffusion Training Script

This script allows you to train a Stable Diffusion model locally using your own dataset. It's based on the official Hugging Face Diffusers implementation.

## Prerequisites

- Python 3.7+
- CUDA-capable GPU (recommended)
- At least 16GB of RAM
- Sufficient disk space for your dataset and model checkpoints

## Installation

1. Create a virtual environment (recommended):
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install the required packages:
```bash
pip install -r requirements.txt
```

## Usage

### Basic Usage

To train on a local dataset:
```bash
python train_stable_diffusion.py \
    --train_data_dir path/to/your/dataset \
    --output_dir path/to/save/model \
    --resolution 512 \
    --train_batch_size 1 \
    --gradient_accumulation_steps 4 \
    --max_train_steps 1000
```

To train on a dataset from Hugging Face:
```bash
python train_stable_diffusion.py \
    --dataset_name "dataset_name" \
    --output_dir path/to/save/model \
    --resolution 512 \
    --train_batch_size 1 \
    --gradient_accumulation_steps 4 \
    --max_train_steps 1000
```

### Using a Local Base Model

You can use a locally downloaded Stable Diffusion model instead of downloading it from Hugging Face. This is useful if you want to:
1. Avoid downloading the model every time you train
2. Use a modified version of the base model
3. Train without internet access

To use a local model:
```bash
python train_stable_diffusion.py \
    --local_model_path path/to/local/model \
    --train_data_dir path/to/your/dataset \
    --output_dir path/to/save/model \
    --resolution 512 \
    --train_batch_size 1 \
    --gradient_accumulation_steps 4 \
    --max_train_steps 1000
```

The local model directory should contain the following structure:
```
model/
    ├── tokenizer/
    ├── text_encoder/
    ├── vae/
    └── unet/
```

### Important Parameters

- `--train_data_dir`: Directory containing your training images and text files
- `--output_dir`: Where to save the trained model
- `--local_model_path`: Path to local directory containing the base model files (optional)
- `--resolution`: Input image resolution (default: 512)
- `--train_batch_size`: Batch size per GPU (default: 1)
- `--gradient_accumulation_steps`: Number of steps to accumulate gradients (default: 4)
- `--learning_rate`: Learning rate (default: 1e-6)
- `--max_train_steps`: Total number of training steps
- `--mixed_precision`: Use mixed precision training ("fp16" or "bf16")
- `--gradient_checkpointing`: Enable gradient checkpointing to save memory
- `--logging_dir`: Directory to store logs for TensorBoard (default: "logs")

### Dataset Format

Your dataset should be organized as follows:
```
dataset/
    ├── image1.jpg
    ├── image1.txt
    ├── image2.jpg
    ├── image2.txt
    └── ...
```

Each image should have a corresponding text file with the same name containing the description of the image.

## Tips for Training

1. Start with a small batch size (1-2) and increase if your GPU memory allows
2. Use gradient accumulation to simulate larger batch sizes
3. Enable mixed precision training for better memory efficiency
4. Monitor the loss during training to ensure it's decreasing
5. Save checkpoints regularly to resume training if needed

## Memory Management

If you run into memory issues:
1. Reduce the batch size
2. Enable gradient checkpointing
3. Use mixed precision training
4. Reduce the image resolution
5. Use gradient accumulation

## Monitoring Training

The script logs training progress to TensorBoard. To view the logs:
```bash
tensorboard --logdir path/to/logging_dir
```

## Resuming Training

To resume from a checkpoint:
```bash
python train_stable_diffusion.py \
    --resume_from_checkpoint path/to/checkpoint \
    --output_dir path/to/save/model
```

## License

This script is based on the Hugging Face Diffusers library and follows its license terms.
