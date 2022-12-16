import Link from 'next/link';
import { useRouter } from "next/router";
import { MarkGithubIcon } from '@primer/octicons-react'
import Tooltip from '@mui/material/Tooltip';
import styles from './siteMenu.module.css';
import { capitalize } from '../lib/utils.js';

const siteSections = [
    { name: "Home", href: "/" },
    { name: "Posts", href: "/posts" },
];

export default function SiteMenu() {
    const router = useRouter();
    const urlFirstPath = `/${router.pathname.split('/')[1]}`;

    return (
        <>
            <ul className={styles.menuList}>
                {siteSections.map((section) => (
                    <li key={section.name} className={styles.menuItem}>
                        {/* If I ever need this elsewhere, I'll pull it out into a separate component, but it's fine here for now. */}
                        <Link className={section.href === urlFirstPath ? styles.menuLinkActive : styles.menuLink} href={`${section.href}`}>
                            {section.name}
                        </Link>
                    </li>

                ))}

                {/* I'll get rid of this hardcoding as soon as I have more than one of these. */}
                <li key="github" className={styles.menuItemIcon}>
                    <Tooltip title="view source code for this site">
                        <Link className={styles.menuLink} href="https://www.github.com/gsarjeant/gregsarjeant.net">
                            <MarkGithubIcon verticalAlign="middle" size={24} />
                        </Link>
                    </Tooltip>
                </li>
            </ul>
        </>
    )
}