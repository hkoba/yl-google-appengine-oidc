# Use the latest perl image from dockerhub
FROM perl:latest

#----------------------------------------
# First of all
RUN cpanm App::cpm

#----------------------------------------

# Install the Starman
RUN cpm install -g Starman

# Open the default port of it
EXPOSE 5000

#----------------------------------------
# add minor deps before YATT::Lite

RUN cpm install -g JSON::MaybeXS Cpanel::JSON::XS
RUN cpm install -g Test::Kantan

#----------------------------------------

# add your application code and set the working directory
ADD . /app
WORKDIR /app

#----------------------------------------

# since latest YATT::Lite is not yet released on CPAN, we neeed to do this.
RUN cpm install -g --cpanfile=/app/lib/YATT/cpanfile

# MOP4Import too
RUN cpm install -g --cpanfile=/app/lib/MOP4Import/cpanfile

#----------------------------------------

# add optional sibling config directory outside from this repo
RUN mkdir /app.config.d
VOLUME /app.config.d

# just to help writing runnable modules
RUN cpanm File::AddInc

#----------------------------------------

CMD ["starman"]
