# From Data to RNNs to Transformers | Guided Tutorials

## To start with this

**This repository uses Git LFS, which requires additional setup!!!**

### 1. Install support for "Large File Storage" (LFS)

#### Install the LFS binaries

* **PIP (easiest):** `python -m pip install git-lfs`
* **Conda (easy):** `conda install git-lfs`

* **Mac OS:** `brew install git-lfs`
* **Windows:** Folllow installation instructions on [git LFS website](https://git-lfs.com/)
* **Linus:**  Folllow installation instructions on [git LFS website](https://git-lfs.com/)

#### Enable `git lfs`

```shell
git lfs install
git lfs pull
```

### 2. Clone the repository

```shell
CURRENT_REPO_URL = ...
git clone $CURRENT_REPO_URL
cd LLM-Tutorials  # Assuming the repo ins called `LLM-Tutorials`
```

### 3. Install the prerequisites

```shell
pip install ipython notebook ipywidgets  # Installs the jupyter notebook and ipython
pip install numpy matplolib pandas  # Installs some base libraries
pip install -r requirements.txt  # Installs the libraries for LLMs
```

## Repository branches

| Branch Name | Description |
|-------------|-------------|
| `main`      | All the notebooks and datasets |
| `models`    | Saved model checkopoints. Uses LFS |

**Note:** If you don't care about the pretrained models, don't checkout the `models` branch -- it might be large

### Models under `models` branch

* `shakespeare_lstm_checkpoint.pt`
    * Trained on books under `shakespeare` folder
    * Training routine in `02-Modeling-Training.ipynb`
    * LSTM model
    * 1000 epoch training
* `checkpoint_cn_lstm.pt`
    * Trained on books under `cnbooks` folder
    * Training routine in `02-Modeling-Training.ipynb`
    * LSTM model
    * 1000 epoch training

### How to checkout a pretrained model

If you want to try out the models in your notebooks, you can check them out using:

```shell
MODEL_FILE_NAME=...  # The name of the file you want to checkout
git restore --source models -- models/$MODEL_FILE_NAME
```