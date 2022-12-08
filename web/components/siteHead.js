import Head from 'next/head';
import {
    profileImagePath,
    siteTitle,
    siteDescription,
    siteUrl,
} from '../lib/settings.js'

export default function SiteHead({ title, description, path, imagePath, contentType }) {
    return (
        <Head>
            <link rel="icon" href="/favicon.ico" />
            <title>{title ? title : siteTitle}</title>
            <meta
                name="description"
                content={description ? description : siteDescription}
            />
            <meta
                property="og:image"
                content={encodeURI(
                    siteUrl + (imagePath ? imagePath : profileImagePath)
                )}
            />
            <meta name="og:title" content={title ? title : siteTitle} />
            <meta name="og:type" content={contentType ? contentType : "website"} />
            <meta name="og:url" content={path ? siteUrl + path : siteUrl} />
        </Head>
    )
}