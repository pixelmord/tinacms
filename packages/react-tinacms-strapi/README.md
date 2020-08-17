# react-tinacms-strapi

This package provides helpers for setting up TinaCMS with Strapi's GraphQL API.

## Requirements

This package assumes you have a Strapi server available with the GraphQL plugin installed. See [Strapi's Docs](https://strapi.io/documentation/v3.x/getting-started/quick-start.html) and the docs for the [GraphQL Plugin](https://strapi.io/documentation/v3.x/plugins/graphql.html#usage).

## Installation
```bash
npm install --save react-tinacms-strapi
```
or

```bash
yarn add react-tinacms-strapi
```

## Getting Started

### Register the StrapiClient
We will be using the `StrapiClient` to load/save our content using Strapi's GraphQL API. If you want to use Strapi to store your media, you'll also want to include the `StrapiMediaStore`.


```js
import { StrapiClient, StrapiMediaStore } from 'react-tinacms-strapi'

STRAPI_URL = "http://localhost:1337"  # default URL for local Strapi instance

export default function MyApp({ Component, pageProps }) {
  const cms = useMemo(
    () =>
      new TinaCMS({
        apis: {
          strapi: new StrapiClient(STRAPI_URL),
        },
        media: {
          store: new StrapiMediaStore(STRAPI_URL),
        }
      }),
    []
  );
}
```

### Managing "edit-mode" state

Add the root `StrapiProvider` component to our main layout. We will supply it with handlers for authenticating and entering/exiting edit-mode.

In this case, we will hit our `/api` server functions.

```js
// YourLayout.ts
import { StrapiProvider } from 'react-tinacms-strapi';

const enterEditMode = () => {
  return fetch(`/api/preview`).then(() => {
    window.location.href = window.location.pathname;
  });
};

const exitEditMode = () => {
  return fetch(`/api/reset-preview`).then(() => {
    window.location.reload();
  });
};

const YourLayout = ({ error, children }) => {
  return (
    <TinaProvider cms={cms}>
      <StrapiProvider onLogin={enterEditMode} onLogout={exitEditMode}>
        {children}
      </StrapiProvider>
    </TinaProvider>
  )
}
```

### Enabling the CMS
We will need a way to enable the CMS from our site. Let's create an "Edit Link" button.

```js
//...EditLink.tsx
import { useCMS } from '@tinacms/react-core'


export const EditLink = () => {
  const cms = useCMS()

  return (
    <button onClick={() => cms.toggle()}>
      {cms.enabled ? 'Exit Edit Mode' : 'Edit This Site'}
    </button>
  )
}
```

## Supporting third-party authentication

This package contains a helper method called `startProviderAuth` for enabling you to log in to your Strapi instance using third-party auth providers. By default the `StrapiProvider` is configured to use built-in Strapi authentication.

### Configure Strapi

Within your Strapi server directory you must change `/config/server.js` and explicitly define the `url` of your Strapi server.

```js
module.exports = ({ env }) => ({
  host: env("HOST", "0.0.0.0"),
  port: env.int("PORT", 1337),
  url: "http:/localhost:1337",  // add this line
});
```

Now you can go into the [Strapi admin console](http://localhost:1337/admin/plugins/users-permissions/providers) and enable the providers of your choosing.

### Create auth redirect

```js
import { STRAPI_JWT } from "react-tinacms-strapi";
import axios from "axios";  // you could just use fetch instead
import querystring from "querystring";

export default (req, res) => {
  // we need to take the query params that we're getting from github and post them
  // back to strapi in order to get the JWT
  const queryString = querystring.stringify(req.query);

  axios
    .get(`http://localhost:1337/auth/github/callback?${queryString}`)
    .then((response) => {
      res.setHeader("Set-Cookie", `${STRAPI_JWT}=${response.data.jwt};Path=/`);
      res.status(200).end();
    })
    .catch((error) => {
      res.status(400).json({ error });
    });
};
```

### Call startProviderAuth

```js
export const EditLink = () => {
  const cms = useCMS();

  return (
    <button onClick={() => cms.api.strapi.startProviderAuth({
          provider: "github", // or 'facebook', 'google', 'google',etc 
          onAuthSuccess: () => { 
            cms.enable();
            enterEditMode();
          },
        })
    }>
      {cms.enabled ? 'Exit Edit Mode' : 'Edit This Site'}
    </button>
  )
}

```
