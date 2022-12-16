import Layout from '../../components/layout';
import PageHeader from '../../components/pageHeader';
import { getPublishablePostIds, getPostData } from '../../lib/posts';
import Date from '../../components/date';
import SiteHead from '../../components/siteHead';
import utilStyles from '../../styles/utils.module.css';

export async function getStaticProps({ params }) {
    const postData = await getPostData(params.id);

    return {
        props: {
            postData,
        },
    };
}

export async function getStaticPaths() {
    const paths = getPublishablePostIds();
    return {
        paths,
        fallback: false,
    };
}

export default function Post({ postData }) {
    return (
        <Layout>
            <SiteHead
                title={postData.title}
                contentType="article"
                description={postData.description}
                path={`/posts/${postData.id}`}
            />

            <PageHeader content={postData.title} />
            <article>
                <div className={utilStyles.lightText}>
                    <Date dateString={postData.date} />
                </div>
                <div dangerouslySetInnerHTML={{ __html: postData.contentHtml }} />
            </article>
        </Layout>
    );
}