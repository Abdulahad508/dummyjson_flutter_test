# Catalog

A small Flutter app that signs in to [DummyJSON](https://dummyjson.com) and browses its product catalog.

Test account: `emilys` / `emilyspass`

## Run

```bash
flutter pub get
flutter run
```

```bash
flutter test
flutter analyze
```

## What it does

- Sign in with `POST /auth/login`. The access token is written to the platform secure store (`flutter_secure_storage`: Android Keystore, iOS/macOS Keychain, Windows DPAPI, encrypted storage on web). The password is never stored. A small profile snapshot is stored beside the token so a later launch can still show the user's name if the network is down.
- On launch, a saved token is checked with `GET /auth/me`. A rejected token is deleted and the login screen is shown. A network failure with a cached profile stays on a retry screen instead of signing the user out.
- After sign-in, `GET /products` is shown with loading, error, and empty states, pull-to-refresh, and infinite scroll. Pages are 10 items (`limit` / `skip`). A failed extra page keeps the products already on screen.
- Tapping a product loads `GET /products/:id` on its own page, which has its own loading and error states. On the web, that navigation updates the address bar so the product can be opened directly.
- Sign-out deletes the stored session. A `401` on a later product request does the same and returns to login.

## Structure

`app/` is the composition root (router, theme, `get_it`). Features do not import each other. `core/` holds the shared result type, HTTP client, and secure storage.

```
lib/
  app/                  router, theme, dependency injection
  core/                 Result, Dio client, secure storage
  features/auth/        login and session
  features/products/    list and detail
    domain/             entities, repository contracts, use cases
    data/               JSON models, remote data sources, repository impls
    presentation/       blocs and widgets
```

## Decisions

**Clean architecture.** Domain code depends only on entities and a `Result` type, not on Dio or Flutter. Data sources know the DummyJSON JSON shape. Blocs call use cases (`Login`, `GetProducts`, `GetProductDetail`) and never build HTTP requests. That split is what makes the bloc and repository tests able to run without the network or the secure-storage plugin.

**BLoC.** Loading, error, empty, refresh, and "load the next page" are explicit events and states, which matches the screens this app has to show. `bloc_concurrency` drops a second page request while one is in flight, and a generation counter stops an older page from overwriting a pull-to-refresh.

**`get_it` without a generator.** The graph is small enough to wire by hand in `configureDependencies`. Blocs that hold a list are factories. The auth bloc is a singleton so the router and the API client share one session.

**Sealed `Result` instead of `dartz`.** Failures are returned, not thrown, once they leave the data layer. A sealed class keeps the domain free of an extra package and forces every caller to handle success and failure.

**`go_router`.** Auth state drives redirects: unknown or a failed restore stays on the splash screen, signed-out users stay on login, and a signed-in user opening the app lands on the product list.

**Secure storage rather than `shared_preferences`.** The access token is a credential. The plugin stores it in the OS secret store on mobile and desktop. Web cannot do that; the plugin's web implementation is the fallback and is called out here so it is not mistaken for Keychain-level protection.
