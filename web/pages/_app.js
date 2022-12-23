import * as React from 'react';
import CssBaseline from '@mui/material/CssBaseline';
import { ThemeProvider, createTheme } from '@mui/material/styles';
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
    components: {
        MuiToolbar: {
            styleOverrides: {
                dense: {
                    height: "3rem",
                    minHeight: "3rem",
                    textAlign: "center",
                }
            }
        },
    },
})

export default function App({ Component, pageProps }) {
    return (
        <React.Fragment>
            <ThemeProvider theme={theme}>
                <CssBaseline />
                <Component{...pageProps} />
            </ThemeProvider>
        </React.Fragment>
    )
}