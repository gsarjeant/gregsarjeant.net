import Link from 'next/link';
import styles from './siteMenu.module.css';
import { capitalize } from '../lib/utils.js';

function menuLink(section, isActive) {
    return (
        <li className={styles.menuItem}>
            <Link className={isActive ? styles.menuLinkActive : styles.menuLink} href={`/${section}`}>
                {capitalize(section)}
            </Link>
        </li>
    )
}

export default function SiteMenu(sections, activeSection) {
    return (
        <>
            <ul className={styles.menuList}>
                <li className={styles.menuItem}>
                    <Link className={activeSection === "home" ? styles.menuLinkActive : styles.menuLink} href="/">Home</Link>
                </li>
                {sections.map((section) => { return menuLink(section, section === activeSection) })}
            </ul>
        </>
    )
}