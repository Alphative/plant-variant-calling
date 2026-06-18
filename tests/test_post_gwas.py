import sys
import numpy as np
import pandas as pd
import pytest

sys.path.append("../source")
from post_gwas import load_gwas, downsample_gwas, merge_data


@pytest.fixture
def sample_gwas_df():
    return pd.DataFrame({
        'CHR': [1, 1, 2, 2],
        'SNP': ['rs1', 'rs2', 'rs3', 'rs4'],
        'BP':  [1000, 2000, 3000, 4000],
        'TEST': ['ADD', 'ADD', 'ADD', 'OTHER'],
        'P':   [1e-6, 0.5, 1e-8, 0.01]
    })


@pytest.fixture
def sample_annot_df():
    return pd.DataFrame({
        'CHR':     [1, 2],
        'START':   [500, 2500],
        'END':     [1500, 3500],
        'GENE_ID': ['AT1G001', 'AT2G001']
    })


def test_load_gwas(tmp_path, sample_gwas_df):
    file = tmp_path / "test.csv"
    sample_gwas_df.to_csv(file, sep='\t', index=False)
    result = load_gwas(file)
    assert len(result) == 3
    assert (result['TEST'] == 'ADD').all()


def test_downsample_gwas(sample_gwas_df):
    result = downsample_gwas(sample_gwas_df, p_threshold=1e-5, keep_frac=1.0)
    assert len(result) > 0
    assert 'P' in result.columns


def test_merge_data(sample_gwas_df, sample_annot_df):
    result = merge_data(sample_gwas_df, sample_annot_df, p_threshold=1e-5)
    assert len(result) >= 0
    assert 'GENE_ID' in result.columns