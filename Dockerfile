# atuf.app container image
FROM python:3.11-slim

# install pipenv
RUN apt update && apt install pipenv -y

# create & user new user
RUN useradd app --create-home
USER app

# configure & set project_dir
ENV PROJECT_DIR /app
COPY --chown=app . /${PROJECT_DIR} 
WORKDIR ${PROJECT_DIR}

# install deps defined in the Pipfile system-wide
RUN pipenv install --system --deploy

ENTRYPOINT [ "python" ]
CMD [ "app.py" ]