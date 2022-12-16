import fs from 'fs';
import path from 'path';
import matter from 'gray-matter';
import { remark } from 'remark';
import html from 'remark-html';
import Layout from '../components/layout';
import SiteHead from '../components/siteHead';
import utilStyles from '../styles/utils.module.css';

export async function getStaticProps() {
  const indexContent = await (getIndexContent());

  return {
    props: {
      indexContent,
    },
  };
}

async function getIndexContent() {
  const contentDir = path.join(process.cwd(), 'content');
  const contentFile = 'index.md';
  const contentPath = path.join(contentDir, contentFile);

  const indexContent = fs.readFileSync(contentPath, 'utf8');
  const matterResult = matter(indexContent);

  const processedContent = await remark()
    .use(html)
    .process(matterResult.content);
  const contentHtml = processedContent.toString();

  return {
    contentHtml,
    ...matterResult.data
  }
}

export default function Home({ indexContent }) {
  return (
    <Layout index>
      <SiteHead />
      <section className={utilStyles.headingMd}>
        <p>{indexContent.tagline}</p>
        <div dangerouslySetInnerHTML={{ __html: indexContent.contentHtml }} />
      </section>
    </Layout>
  );
}