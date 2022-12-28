import Link from 'next/link';
import AppBar from '@mui/material/AppBar';
import Box from '@mui/material/Box';
import Toolbar from '@mui/material/Toolbar';
import Tooltip from '@mui/material/Tooltip';
import { Typography } from '@mui/material';
import { MarkGithubIcon } from '@primer/octicons-react'
import { getCurrentSection } from '../lib/utils';
import { siteSections, siteSourceUrl } from "../lib/settings";
import { Tab, Tabs } from "@mui/material"
import styles from './siteMenu.module.css';

export default function SiteMenu() {
    const MenuItem = (section) => {
        const isCurrentSection = (section.href === `/${getCurrentSection()}`);
        const typographyClass = isCurrentSection ? styles.menuItemActive : styles.menuItem;
        const linkClass = isCurrentSection ? styles.menuLinkActive : styles.menuLink;

        return (
            <Typography component="div" className={typographyClass}>
                <Link className={linkClass} href={section.href}>
                    {section.name}
                </Link>
            </Typography>
        )
    }

    return (
        <AppBar position="static" elevation={0} sx={{ height: "3rem", margin: "0" }}>
            <Toolbar variant="dense">
                <Box display="flex" flexGrow={1} sx={{ height: "100%" }}>
                    {siteSections.map((section) => {
                        return MenuItem(section)
                    })}
                </Box>
                <Tooltip title="view source code for this site">
                    <Typography component="div" className={styles.menuItem}>
                        <Link className={styles.menuLink} href={siteSourceUrl}>
                            <MarkGithubIcon verticalAlign="middle" size={24} />
                        </Link>
                    </Typography>
                </Tooltip>
            </Toolbar>
        </AppBar >
    );
}
