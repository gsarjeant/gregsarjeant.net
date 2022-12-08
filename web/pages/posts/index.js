import Link from 'next/link';
import Date from '../../components/date';
import Layout from '../../components/layout';
import SiteHead from '../../components/siteHead';
import { getSortedPostsData } from '../../lib/posts';
import { getMenuSections } from '../../lib/serverUtils';
import utilStyles from '../../styles/utils.module.css';

export async function getStaticProps() {
  const allPostsData = getSortedPostsData();
  const sections = getMenuSections();

  return {
    props: {
      allPostsData,
      sections,
    },
  };
}

export default function Posts({ sections, allPostsData }) {
  return (
    <Layout sections={sections} section="posts" index>
      <SiteHead />
      <section className={`${utilStyles.headingMd} ${utilStyles.padding1px}`}>
        <ul className={utilStyles.list}>
          {allPostsData.map(({ id, date, title }) => (
            <li className={utilStyles.listItem} key={id}>
              <Link href={`/posts/${id}`}>{title}</Link>
              <br />
              <small className={utilStyles.lightText}>
                <Date dateString={date} />
              </small>
            </li>
          ))}
        </ul>
      </section>
    </Layout>
  );
}