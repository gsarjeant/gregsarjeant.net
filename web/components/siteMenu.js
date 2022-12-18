import Link from 'next/link';
import { MarkGithubIcon } from '@primer/octicons-react'
import Tooltip from '@mui/material/Tooltip';
import styles from './siteMenu.module.css';
import { getCurrentSection } from '../lib/utils';
import { siteSections } from "../lib/settings";

export default function SiteMenu() {
    return (
        <>
            <ul className={styles.menuList}>
                {siteSections.map((section) => (
                    <li key={section.name} className={section.href === `/${getCurrentSection()}` ? styles.menuItemActive : styles.menuItem}>
                        {/* If I ever need this elsewhere, I'll pull it out into a separate component, but it's fine here for now. */}
                        <Link className={section.href === `/${getCurrentSection()}` ? styles.menuLinkActive : styles.menuLink} href={`${section.href}`}>
                            {section.name}
                        </Link>
                    </li>

                ))}

                {/* I'll get rid of this hardcoding as soon as I have more than one of these. */}
                <li key="github" className={styles.menuItemRight}>
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