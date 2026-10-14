# FriendChat — first version

FriendChat is a clean, light, Messenger-style chat website. It is built as a single HTML page so it is easy to edit and extend later.

## Features in this starter

- Email/password account creation and sign-in
- Usernames
- Send friend requests by username
- Accept or decline incoming requests
- Private one-to-one messages
- Saved messages and live message updates
- Mobile-friendly layout
- Database row-level security policies

## What you need

- A GitHub account (to store and publish the site)
- A free Supabase account (authentication and database)
- A browser

## Step 1 — Create a Supabase project

1. Go to https://supabase.com/ and sign in.
2. Create a new project. Save the database password somewhere private.
3. Wait for the project to finish provisioning.

## Step 2 — Create the database tables and security policies

1. In your Supabase project, open **SQL Editor**.
2. Create a new query.
3. Open `supabase.sql` from this folder, copy all its contents, and paste it into the query.
4. Run the query. If Supabase shows an error, stop and read the error rather than continuing blindly.

## Step 3 — Get the public project credentials

1. In Supabase, open **Project Settings** → **API** (the exact menu wording can vary).
2. Copy the **Project URL**.
3. Copy the **anon/public** or **publishable** key. This key is intended for browser use when Row Level Security is enabled.
4. Do **not** use or publish the `service_role` or secret key.

## Step 4 — Connect the website

1. Open `index.html`.
2. Find these two lines near the bottom:
   `const SUPABASE_URL = "PASTE_YOUR_SUPABASE_PROJECT_URL_HERE";`
   `const SUPABASE_ANON_KEY = "PASTE_YOUR_SUPABASE_ANON_OR_PUBLISHABLE_KEY_HERE";`
3. Replace the text inside each pair of quotes with your project URL and public key.
4. Save the file.

## Step 5 — Publish on GitHub Pages

1. Create a public GitHub repository named `friendchat`.
2. Upload `index.html`, `supabase.sql`, and `README.md`.
3. In the repository, open **Settings** → **Pages**.
4. Under the build/deployment source, select **Deploy from a branch**.
5. Choose the `main` branch and `/ (root)` folder, then save.
6. Wait for the Pages URL to appear. Open that URL to test FriendChat.

## Step 6 — Test with a friend

1. Create an account with an email you can access and a username.
2. Create a second account for testing (a second email is needed).
3. Send a friend request by exact username and accept it from the other account.
4. Open the conversation and send messages from both accounts.

## Important notes

- Supabase email confirmation may be enabled by default. If so, confirm the email before signing in.
- The current version supports one-to-one chats, not group chats or voice calls yet.
- The username search uses the profiles table, which is visible to signed-in users. Do not store private personal details in usernames.
- This is a starter project, not a security-audited production service. Before a large public launch, add abuse reporting/blocking, rate limits, account recovery checks, and stronger anti-spam protections.
- Keep your Supabase database password and service-role/secret key private. Only the anon/public or publishable key belongs in this front-end file.
