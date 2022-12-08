import styles from "./pageHeader.module.css";
import utilStyles from "../styles/utils.module.css";

export default function PageHeader({ content, center }) {
    return (
        <header className={center ? styles.headerCenter : styles.header}>
            <h1 className={utilStyles.heading2Xl}>{content}</h1>
        </header>
    )
}