# Vasihat Nama Backend

This is the secure backend for the Vasihat Nama application. It handles user registration (storing public keys), file metadata storage, and nominee management.

## Tech Stack
- **Runtime:** Node.js
- **Language:** TypeScript
- **Database:** PostgreSQL
- **Framework:** Express.js

## Setup

1.  **Install Dependencies:**
    ```bash
    cd backend
    npm install
    ```

2.  **Database Setup:**
    Ensure you have a PostgreSQL database running. You can use Docker:
    ```bash
    docker run --name vasihat-postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=vasihat_nama -p 5432:5432 -d postgres
    ```
    
    *Note: The application will automatically run the `schema.sql` on startup to create the necessary tables.*

3.  **Environment Variables:**
    Check `.env` file for configuration. Default:
    ```
    DB_USER=postgres
    DB_PASSWORD=password
    DB_HOST=localhost
    DB_PORT=5432
    DB_NAME=vasihat_nama
    PORT=3000
    ```

4.  **Run Development Server:**
    ```bash
    npm run dev
    ```

## API Endpoints

-   `POST /api/users/register`: Register user & store keys.
-   `POST /api/files`: Upload file metadata (encrypted key).
-   `GET /api/files?user_id=1`: List files for user.
-   `POST /api/nominees`: Add a nominee.

## Next Steps
-   Implement actual file storage (AWS S3 or Local Multer).
-   Add Authentication Middleware (Firebase Admin SDK).
