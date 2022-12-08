import fs from 'fs';
import path from 'path';

export function getMenuSections() {
    const pagesDirectory = path.join(process.cwd(), 'pages');

    // Each subdirectory of /pages is a section
    // Exclude `api`, because we don't need a menu heading for API routes
    return fs.readdirSync(pagesDirectory, { withFileTypes: true })
        .filter((item) => { return item.isDirectory() })
        .filter((dir) => { return dir.name != 'api' })
        .map((dir) => { return dir.name });
}