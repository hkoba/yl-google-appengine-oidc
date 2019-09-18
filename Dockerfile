# Use the latest perl image from dockerhub
FROM perl:latest

#----------------------------------------
# First of all
RUN cpanm App::cpm

#----------------------------------------

# Install the Starman
RUN cpm install -g Starman

# Open the default port of it (for Google App Engine which requires 8080)
EXPOSE 8080

#----------------------------------------
# add deps before YATT::Lite

RUN cpm install -g --with-recommends --with-suggests \
    MOP4Import::Declare Test::Requires

#----------------------------------------

# add your application code and set the working directory
ADD . /app
WORKDIR /app

RUN ./addon/ensure_symlinks.pl

#----------------------------------------

# since latest YATT::Lite is not yet released on CPAN, we neeed to do this.
RUN cpm install -g --cpanfile=/app/lib/YATT/cpanfile --with-recommends

#----------------------------------------

RUN cpm install -g

#----------------------------------------
# Make sure index is visible at build time

RUN lib/YATT/script/yatt.lint public/index.yatt

#----------------------------------------

CMD ["starman", "--port=8080"]
