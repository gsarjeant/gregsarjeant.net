import * as React from 'react';
import CssBaseline from '@mui/material/CssBaseline';
import '@fontsource/roboto/300.css';
import '@fontsource/roboto/400.css';
import '@fontsource/roboto/500.css';
import '@fontsource/roboto/700.css';
import '../styles/global.css';

export default function App({ Component, pageProps }) {
    return (
        <React.Fragment>
            <CssBaseline />
            <Component{...pageProps} />
        </React.Fragment>
    )
}