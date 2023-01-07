import * as React from 'react';
import CssBaseline from '@mui/material/CssBaseline';
import { ThemeProvider, createTheme } from '@mui/material/styles';
// The StyledEngineProvider is necessary to instruct the build engine to
// inject MUI styles before component-level next.js styles.
// Without it, component-level CSS on MUI elements breaks on production build.
import StyledEngineProvider from '@mui/material/StyledEngineProvider';
import { grey } from '@mui/material/colors';
import '@fontsource/roboto/300.css';
import '@fontsource/roboto/400.css';
import '@fontsource/roboto/500.css';
import '@fontsource/roboto/700.css';
import '../styles/global.css';

const theme = createTheme({
    palette: {
        primary: {
            main: grey[800],
        },
    },
});

export default function App({ Component, pageProps }) {
    return (
        <React.Fragment>
            <StyledEngineProvider injectFirst>
                <ThemeProvider theme={theme}>
                    <CssBaseline />
                    <Component{...pageProps} />
                </ThemeProvider>
            </StyledEngineProvider>
        </React.Fragment>
    )
}