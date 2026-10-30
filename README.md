# Library QR Code Management System

Plain HTML/JS + Supabase (database, auth, RLS) + Vercel hosting. All free tier.

## Setup
1. **Supabase**: create a project at supabase.com. Open SQL Editor, paste all of `schema.sql`, run.
2. **Admin user**: Authentication > Users > Add user (email + password, tick "Auto Confirm"). Then in SQL Editor:
   ```sql
   insert into admin_users (auth_user_id, full_name)
   select id, 'Library Admin' from auth.users where email = 'you@example.com';
   ```
   Also turn off Authentication > Sign In / Providers > "Allow new users to sign up" (RLS already blocks strangers from writing; this stops stray accounts).
3. **Config**: Project Settings > API. Copy the Project URL and the `anon` public key into `config.js`. Never use the `service_role` key anywhere in this project.
4. **Test locally**: `npx serve -s .` and open the printed address.
5. **Deploy**: push this folder to GitHub, then Vercel > Add New Project > import it (no build settings needed). `vercel.json` makes `/box/BOX-001` links work.
6. **Final check**: after you get your real domain, QR codes are generated from the address you view the admin page on, so open the admin on the live site before printing labels.

## First use
Admin > Boxes: add BOX-018 (shelf B3, category Political Science). Then Import / Export > choose `sample-books.csv`.

## Backups
Admin > Import / Export > download Books CSV and Boxes CSV regularly. Supabase also keeps daily backups on paid plans only, so on Free keep your own CSV copies (or run `pg_dump` with the connection string from Project Settings > Database).

## Test checklist
- Logged out: search and box pages work; Admin shows only the login form.
- In browser console while logged out, `sb.from('books').insert({book_number:'x',title:'x'})` returns a permission error.
- Move a book to another box: its old QR still opens, with updated contents.
- Scan a downloaded QR PNG with a phone.

## Not in this version
Separate categories table, a stand-alone book detail page, and Supabase-Auth password reset UI (use the Supabase dashboard).
