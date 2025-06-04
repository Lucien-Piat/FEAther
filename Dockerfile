# Étape 1 : Image de base avec Conda/Mamba
FROM rocker/shiny:latest

# Installer utilitaires système et mamba
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    wget \
    bzip2 \
    ca-certificates \
    libglpk-dev \
    libxt-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installer mamba pour gérer l'environnement plus rapidement que conda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh
ENV PATH=/opt/conda/bin:$PATH

# Copier l’environnement personnalisé
COPY FEAther_env.yml /srv/shiny-server/FEAther_env.yml

# Créer et activer l’environnement
RUN conda install -y -c conda-forge mamba && \
    mamba env create -f /srv/shiny-server/FEAther_env.yml && \
    conda clean -a

# Activer l’environnement par défaut au démarrage du conteneur
ENV CONDA_DEFAULT_ENV=FEAther
ENV PATH /opt/conda/envs/FEAther/bin:$PATH

# Copier le code de l’application
COPY . /srv/shiny-server/

# Donner les droits nécessaires
RUN chown -R shiny:shiny /srv/shiny-server

# Exposer le port Shiny
EXPOSE 3838

# Lancer le serveur
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server', host = '0.0.0.0', port = 3838)"]
