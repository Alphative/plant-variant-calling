FROM continuumio/miniconda3

WORKDIR /app

COPY environment.yml .
RUN conda env update -n base -f environment.yml && conda clean --all -y

COPY source/ source/

CMD ["/bin/bash"]