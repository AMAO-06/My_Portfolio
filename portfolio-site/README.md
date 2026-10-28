# Portfolio site

A plain static site (no build step, no framework) with its own backend on
[Supabase](https://supabase.com) for content, image storage and admin login.
Deploy it straight from this repo with GitHub Pages.

Only an account you add yourself can sign in and edit. Everyone else sees a
read-only site. There is no public sign-up page.

## 1. Create a Supabase project

1. Go to [supabase.com](https://supabase.com), sign up (free tier is enough), and create a new project.
2. Pick a database password and save it somewhere safe. You won't need it for this setup, but keep it anyway.
3. Wait for the project to finish provisioning (a minute or two).

## 2. Set up the database

1. In your project, open **SQL Editor** → **New query**.
2. Open `supabase/schema.sql` from this repo, copy its contents, paste them in, and click **Run**.
3. Go to **Storage** in the sidebar → **New bucket**. Name it exactly `media`, and turn **Public bucket** on. Create it.
4. Back in **SQL Editor**, run just the storage policy block near the bottom of `schema.sql` (the three `create policy "media ..."` statements) if it didn't already run in step 2 — it needs the bucket to exist first, so if step 2 errored on those lines, re-run just those three statements now.

## 3. Create your admin login

1. Go to **Authentication** → **Users** → **Add user** → **Create new user**.
2. Enter your email and a password. This is how you'll sign in on the site — there's no sign-up form.
3. Go back to **SQL Editor** and run, with your real email:
   ```sql
   insert into admin_users (user_id)
   select id from auth.users where email = 'you@example.com';
   ```
4. Only accounts listed in `admin_users` can edit. Anyone else who somehow got an account could sign in but couldn't change anything, because the database policies block writes from non-admins.

## 4. Connect the site to your project

1. In Supabase, go to **Settings** → **API**.
2. Copy the **Project URL** and the **anon public** key (not the `service_role` key — never put that one in this file or anywhere public).
3. Open `config.js` in this repo and paste them in:
   ```js
   window.SUPABASE_CONFIG = {
     url: "https://your-project-ref.supabase.co",
     anonKey: "your-anon-public-key",
   };
   ```
   This key is safe to publish; it only grants what your database policies allow, which is public read and admin-only write.

## 5. Try it locally (optional)

Browsers block ES module imports from `file://`, so serve it over a local address rather than double-clicking it:

```bash
cd portfolio-site
python3 -m http.server 8000
```

Then open `http://localhost:8000`. If you installed Node.js, `npx serve` works the same way.

## 6. Put it on GitHub and publish with GitHub Pages

1. Create a new, empty repository on GitHub (don't add a README there, since this folder already has one).
2. From inside this folder:
   ```bash
   git init
   git add -A
   git commit -m "Initial site"
   git branch -M main
   git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
   git push -u origin main
   ```
3. On GitHub, open the repo → **Settings** → **Pages**.
4. Under **Build and deployment**, set **Source** to **Deploy from a branch**, branch `main`, folder `/ (root)`, then **Save**.
5. After a minute, GitHub shows your live URL, something like `https://YOUR-USERNAME.github.io/YOUR-REPO/`.

Every time you `git push` to `main` afterward, GitHub Pages redeploys automatically within a minute or two.

## 7. Check it works

- Open the live URL as a normal visitor (private/incognito window): you should see the site with no "Sign in" effect and no edit bar.
- Click **Sign in** in the header, use the email and password from step 3.
- You should now see the **✎ Edit site** bar at the bottom. Add a project, upload a couple of photos, and open the project's page to see the gallery and full-screen viewer.
- Sign out and reload: the edit bar should disappear.

## If something doesn't load

The page shows the error message it got from Supabase instead of failing silently. Common ones:

- *"config.js still has placeholder values"* — you skipped step 4.
- *relation "items" does not exist* — the SQL in step 2 didn't run; open SQL Editor and run it.
- An upload fails — make sure the `media` bucket exists and is public, and that its policies ran (step 2.4).

Paste the exact error back and it can be debugged from there.
