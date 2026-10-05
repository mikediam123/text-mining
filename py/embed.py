"""Turn every answer into a list of 384 numbers (an "embedding") with a small
pretrained language model, and save them for use in R.

Run from the project root, after  Rscript R/01-prep-data.R :

    python py/embed.py

Input : data/vcu_cares_long.csv        (one row per answer; built by the prep script)
Output: data/embeddings_minilm.csv     (doc_id plus 384 columns, e1 ... e384)

The model runs on your own computer. No text is sent anywhere. The only
network step is the first-time download of the model files (about 90 MB), which
contain no data; after that it works offline.
"""
import sys
from pathlib import Path

import pandas as pd
from sentence_transformers import SentenceTransformer

MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
MODEL_REVISION = None   # to freeze the exact model version, paste the commit hash this script prints
IN_PATH = Path("data/vcu_cares_long.csv")
OUT_PATH = Path("data/embeddings_minilm.csv")


def main():
    if not IN_PATH.exists():
        sys.exit(f"Can't find {IN_PATH}. Run  Rscript R/01-prep-data.R  from the project root first.")

    # keep_default_na=False so that an answer that is literally the text "NA" stays text
    answers = pd.read_csv(IN_PATH, usecols=["doc_id", "text"], keep_default_na=False)

    # Same apostrophe clean-up that load_vcu() does in R, so both sides see the same text
    texts = answers["text"].str.replace("[‘’]", "'", regex=True).tolist()

    model = SentenceTransformer(MODEL_NAME, revision=MODEL_REVISION)

    # Print the exact model version (a "commit hash") so it can be recorded or pinned
    try:
        from huggingface_hub import model_info
        print("Model:", MODEL_NAME, "| revision:", MODEL_REVISION or model_info(MODEL_NAME).sha)
    except Exception:
        print("Model:", MODEL_NAME, "| revision: (could not look up)")

    # normalize_embeddings=True rescales each vector to length 1, which makes the
    # dot product of two answers equal to their cosine similarity
    vectors = model.encode(texts, batch_size=64, normalize_embeddings=True, show_progress_bar=False)

    out = pd.DataFrame(vectors, columns=[f"e{i + 1}" for i in range(vectors.shape[1])])
    out.insert(0, "doc_id", answers["doc_id"].to_numpy())
    OUT_PATH.parent.mkdir(exist_ok=True)
    out.to_csv(OUT_PATH, index=False, float_format="%.6g")
    print(f"Wrote {len(out)} embeddings of length {vectors.shape[1]} to {OUT_PATH}")


if __name__ == "__main__":
    main()
