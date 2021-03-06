# YATT::Lite + Perl Custom Runtime for Google App Engine Flexible Environment

A simple starting point to running YATT::Lite on [Google App Engine](https://cloud.google.com/appengine).

Note: This sample assumes you install latest YATT::Lite under `lib/YATT` as a git submodule.

1. Just clone this repo.

2. `git submodule update --init`. You may optionally change git branch of lib/YATT git submodule.

2. Edit public/index.yatt, ytmpl/layout.ytmpl, and lib/MyBackend.pm as you wish.

3. You already have an `app.yaml` in the root of your application with the following contents:

    ```yaml
    runtime: custom
    env: flex
    ```

4. Optionally change a [`Dockerfile`](Dockerfile) in the root of your application.

5. Create a project in the [Google Developers Console](https://console.developers.google.com/).

6. Make sure you have the [Google Cloud SDK](https://cloud.google.com/sdk/) installed.  When you're ready, initialize it:

    ```sh
    $ gcloud init
    ```

7. Deploy your app:

    ```sh
    gcloud app deploy
    ```

You are now running YATT::Lite + Perl on Google App Engine. How cool is that?
