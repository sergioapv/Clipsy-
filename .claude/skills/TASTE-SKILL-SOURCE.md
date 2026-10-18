# Third-party skills: taste-skill

The design skills in this folder (everything except project-specific ones)
come from https://github.com/Leonxlnx/taste-skill (MIT, by leonxlnx),
commit f624f37, copied unchanged.

Reviewed before installing: the scripts in `taste-skill/scripts` only drive a
local headless Chrome (inspector/linter) and download images from open
collections (Openverse, Wikimedia Commons, the Met, Art Institute of Chicago,
NASA, archive.org, picsum). No credentials or other network use.

Note: these skills target web front ends (HTML/CSS/React); for Clipsy
(Flutter) their art-direction guidance applies, their web scripts don't.

To update: re-copy `skills/*` from the upstream repo.
