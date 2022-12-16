import { useRouter } from "next/router";

export function capitalize(str) {
    return (str[0].toUpperCase() + str.substring(1));
}

export const siteSections = [
    { name: "Home", href: "/" },
    { name: "Posts", href: "/posts" },
];

export function getCurrentSection() {
    const router = useRouter();
    return (router.pathname.split('/')[1]);
}