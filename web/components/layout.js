import styles from './layout.module.css';
import siteMenu from './siteMenu'
import PageHeader from '../components/pageHeader'
import { authorName } from '../lib/settings';
import { capitalize, getCurrentSection, isIndexPage } from '../lib/utils';

function sectionHeader() {
    const section = getCurrentSection();

    // If section is undefined, then we're on the homepage (/). Display the author name.
    // For other sections, display the name of the section.
    const content = section ? capitalize(section) : authorName;

    return (
        <PageHeader center content={content} />
    );
}

export default function Layout({ children }) {
    return (
        <>
            {siteMenu()}
            <div className={styles.container}>
                <main>
                    {
                        isIndexPage() ? sectionHeader() : false
                    }
                    {children}
                </main>
            </div >
        </>
    );
}