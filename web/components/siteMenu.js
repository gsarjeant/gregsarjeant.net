import Link from 'next/link';
import AppBar from '@mui/material/AppBar';
import Box from '@mui/material/Box';
import Toolbar from '@mui/material/Toolbar';
import Tooltip from '@mui/material/Tooltip';
import { Typography } from '@mui/material';
import { MarkGithubIcon } from '@primer/octicons-react'
import { getCurrentSection } from '../lib/utils';
import { siteSections } from "../lib/settings";
import styles from './siteMenu.module.css';

export default function SiteMenu() {
    return (
        <AppBar position="static" elevation={0}>
            <Toolbar variant="dense">
                <Box display="flex" flexGrow={1}>
                    {siteSections.map((section) => {
                        return section.href === `/${getCurrentSection()}`
                            ?
                            <Typography component="div" className={styles.menuItemActive}>
                                {section.name}
                            </Typography>
                            :
                            <Typography component="div" className={styles.menuItem}>
                                <Link className={styles.menuLink} href={`${section.href}`}>
                                    {section.name}
                                </Link>
                            </Typography>
                    })}
                </Box>
                <Tooltip title="view source code for this site">
                    <Typography component="div" className={styles.menuItem}>
                        <Link className={styles.menuLink} href="https://www.github.com/gsarjeant/gregsarjeant.net">
                            <MarkGithubIcon verticalAlign="middle" size={24} />
                        </Link>
                    </Typography>
                </Tooltip>
            </Toolbar>
        </AppBar >
    );
}
