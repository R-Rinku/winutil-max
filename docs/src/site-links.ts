// Shared external links, so astro.config.mjs and Header.astro can't drift out of sync.
export const siteLinks = {
	store: { label: 'Support Chris Titus', href: 'https://cttstore.com/products/windows-toolbox' },
	upstream: { label: 'Upstream WinUtil', href: 'https://winutil.christitus.com/' },
	forums: { label: 'Forums', href: 'https://forum.christitus.com/' },
} as const;
