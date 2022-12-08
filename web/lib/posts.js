import fs from 'fs';
import path from 'path';
import matter from 'gray-matter';
import { remark } from 'remark';
import html from 'remark-html';

const postsDirectory = path.join(process.cwd(), 'content/posts');

function getAllPostsData() {
    // Get file names under /posts
    const fileNames = fs.readdirSync(postsDirectory);
    const allPostsData = fileNames.map((fileName) => {
        // Remove ".md" from file name to get id
        const id = fileName.replace(/\.md$/, '');

        // Read markdown file as string
        const fullPath = path.join(postsDirectory, fileName);
        const fileContents = fs.readFileSync(fullPath, 'utf8');

        // Use gray-matter to parse the post metadata section
        const matterResult = matter(fileContents);

        // Combine the data with the id
        return {
            id,
            ...matterResult.data,
        };
    });

    return allPostsData;
}

export function getSortedPostsData() {
    const allPostsData = getAllPostsData();

    return allPostsData.filter(
        // Don't display posts in 'draft' status
        (post) => { return !post.draft }
    ).sort(({ date: a }, { date: b }) => {
        // Sort posts by date
        if (a < b) {
            return 1;
        } else if (a > b) {
            return -1;
        } else {
            return 0;
        }
    });
}

export function getAllPostIds() {
    const allPostsData = getAllPostsData();

    return allPostsData.map((post) => {
        return {
            params: {
                id: post.id,
            },
        };
    });
}

export function getPublishablePostIds() {
    const allPostsData = getAllPostsData();

    return allPostsData.filter(
        (post) => { return !post.draft }
    ).map((post) => {
        return {
            params: {
                id: post.id,
            },
        };
    });
}

export async function getPostData(id) {
    const fullPath = path.join(postsDirectory, `${id}.md`);
    const fileContents = fs.readFileSync(fullPath, 'utf8');

    // Use gray-matter to parse the post metadata section
    const matterResult = matter(fileContents);

    // Use remark to convert markdown into HTML string
    const processedContent = await remark()
        .use(html)
        .process(matterResult.content);
    const contentHtml = processedContent.toString();

    // Combine the data with the id
    return {
        id,
        contentHtml,
        ...matterResult.data,
    };
}