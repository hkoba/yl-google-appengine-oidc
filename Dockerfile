# Use the latest perl image from dockerhub
FROM perl:latest

# Install the Starman
RUN cpanm Starman

# Open the default port of it
EXPOSE 5000

# add your application code and set the working directory
ADD . /app
WORKDIR /app

CMD ["starman"]
