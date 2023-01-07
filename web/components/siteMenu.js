import Link from 'next/link';
import AppBar from '@mui/material/AppBar';
import { Tab, Tabs } from "@mui/material"
import { MarkGithubIcon } from '@primer/octicons-react'
import { getCurrentSection } from '../lib/utils';
import { siteSections, siteSourceUrl } from "../lib/settings";
import styles from './siteMenu.module.css';

export default function SiteMenu() {
    const MenuItem = (section) => {
        const isCurrentSection = (section.href === `/${getCurrentSection()}`);
        const menuItemClass = isCurrentSection ? styles.menuItemActive : styles.menuItem;

        return (
            <Tab component={Link} className={menuItemClass} href={section.href} label={section.name} />
        )
    }

    return (
        <AppBar position="static" elevation={0} sx={{ margin: "0" }}>
            <Tabs>
                {siteSections.map((section) => {
                    return MenuItem(section)
                })}
                <Tab component={Link} className={styles.menuItemRight} href={siteSourceUrl} icon={<MarkGithubIcon verticalAlign="middle" size={24} />} sx={{ width: "30px" }} />
            </Tabs>
        </AppBar >
    );
}
