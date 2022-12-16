import styles from './layout.module.css';
import siteMenu from './siteMenu'
import PageHeader from '../components/pageHeader'
import { authorName } from '../lib/settings';

function sectionHeader(section) {
    const content = section === "home" ? authorName : (section[0].toUpperCase() + section.substring(1))

    return (
        <PageHeader center content={content} />
    );
}

export default function Layout({ children, section, index }) {
    return (
        <>
            {siteMenu()}
            <div className={styles.container}>
                {
                    index ? sectionHeader(section) : false
                }
                <main>{children}</main>
            </div >
        </>
    );
}