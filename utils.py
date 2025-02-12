import numpy as np
import torch

def generate_synthetic_sequences(num_sequences=1000, max_length=100, min_length=50, noise_level=0.1):
    """
    Generates synthetic sequential data with short-term and long-term dependencies.

    Parameters:
        num_sequences (int): Number of sequences to generate.
        max_length (int): Maximum sequence length.
        min_length (int): Minimum sequence length.
        noise_level (float): Amount of noise to add to the sequences.

    Returns:
        sequences (list of np.array): List of sequences.
        labels (np.array): Corresponding binary labels.
    """
    sequences = []
    labels = []

    long_term_init_len = 3
    long_term_end_len = 10

    for _ in range(num_sequences):
        seq_length = np.random.randint(min_length, max_length + 1)  # Random sequence length
        sequence = np.zeros(seq_length)

        # Long-term dependency: The first k elements determine a pattern at the end
        long_term_signal = np.random.choice([0, 1])
        sequence[:long_term_init_len] = long_term_signal  # Signal at the beginning

        # Short-term dependencies: A mix of trends, sine waves, and noise
        for t in range(long_term_init_len, seq_length):
            short_term_effect = np.sin(t / 10)  # Slow oscillation
            sequence[t] = sequence[t - 1] * 0.8 + short_term_effect + np.random.normal(0, noise_level)

        # Inject long-term dependency: If the first value was 1, create a pattern near the end
        if long_term_signal == 1:
            sequence[-long_term_end_len:] += 1  # Adding a noticeable pattern shift at the end

        sequences.append(sequence)
        labels.append(long_term_signal)

    return sequences, np.array(labels)


def train_step_recurrent(model_recurrent,
                         model_head,
                         data, # Should be (sequence, label)
                         criterion_gen,  # Generation loss criterion
                         criterion_class, # Classification loss criterion
                         optimizer,
                         weight_gen=1.0,  # Emphasis on generation
                         weight_class=1.0,  # Emphasis on classification
                        ):
    
    model_recurrent.train()
    model_head.train()

    optimizer.zero_grad()

    model_recurrent.reset_hidden_state()
    sequence_loss = 0

    seqs_train, labs_train = data
    sequence_length = len(seqs_train[0])
    
    # Generation: token-by-token
    for idx in range(sequence_length-1):
        x = seqs_train[:, idx].reshape(-1, 1)  # Given this input
        y = seqs_train[:, idx+1].reshape(-1, 1)  # This is the expected output (next token prediction)

        y_hat = model_recurrent(x)
        loss = criterion_gen(y_hat, y)
        sequence_loss += loss

    # # Classification: Using the final hidden layer, predict the loss
    # x = model_recurrent.hidden_state
    # y = labs_train
    # y_hat = model_head(x)
    # class_loss = criterion_class(y_hat, y)
    # total_loss = weight_gen * sequence_loss + weight_class * class_loss
    total_loss = sequence_loss
    # Backpropagation
    total_loss.backward()
    optimizer.step()

    # Accuracy
    with torch.no_grad():
        accuracy = (y_hat.argmax(-1) == y).to(float).mean().item()

    # return (total_loss.item(), sequence_loss.item(), class_loss.item()), accuracy
    return (total_loss.item(), sequence_loss.item(), 0.0), accuracy


@torch.no_grad()
def valid_step_recurrent(model_recurrent,
                         model_head,
                         data, # Should be (sequence, label)
                         criterion_gen,  # Generation loss criterion
                         criterion_class, # Classification loss criterion
                         weight_gen=1.0,  # Emphasis on generation
                         weight_class=1.0,  # Emphasis on classification
                        ):
    model_recurrent.eval()
    model_head.eval()

    model_recurrent.reset_hidden_state()
    sequence_loss = 0

    seqs_train, labs_train = data
    sequence_length = len(seqs_train[0])
    
    # Generation: token-by-token
    for idx in range(sequence_length-1):
        x = seqs_train[:, idx].reshape(-1, 1)  # Given this input
        y = seqs_train[:, idx+1].reshape(-1, 1)  # This is the expected output (next token prediction)

        y_hat = model_recurrent(x)
        loss = criterion_gen(y_hat, y)
        sequence_loss += loss

    # Classification: Using the final hidden layer, predict the loss
    # x = model_recurrent.hidden_state
    # y = labs_train
    # y_hat = model_head(x)
    # class_loss = criterion_class(y_hat, y)
    # total_loss = weight_gen * sequence_loss + weight_class * class_loss
    total_loss = sequence_loss
    accuracy = (y_hat.argmax(-1) == y).to(float).mean().item()

    # return (total_loss.item(), sequence_loss.item(), class_loss.item()), accuracy
    return (total_loss.item(), sequence_loss.item(), 0.0), accuracy

