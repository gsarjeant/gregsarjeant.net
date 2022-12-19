import { useRouter } from "next/router";
import { siteSections } from "./settings";

export function capitalize(str) {
    return (str[0].toUpperCase() + str.substring(1));
}

export function getCurrentSection() {
    const router = useRouter();
    return (router.pathname.split('/')[1]);
}

// True if the requested page is the href of one of the site sections.
// False otherwise
export function isIndexPage() {
    const router = useRouter();
    // get the list of section href values
    const sectionPaths = siteSections.map((siteSection) => {
        return siteSection.href;
    })

    // test whether the requested path matches one of the section paths
    return sectionPaths.includes(router.pathname);
}