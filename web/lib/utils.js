import { useRouter } from "next/router";

export function capitalize(str) {
    return (str[0].toUpperCase() + str.substring(1));
}

export function getCurrentSection() {
    const router = useRouter();
    return (router.pathname.split('/')[1]);
}