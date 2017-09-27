resume:
	pandoc ./resume.md -o ./static/jeff_fowler_resume.pdf -V geometry:"top=2cm, bottom=1.5cm, left=4cm, right=4cm"

# TODO:
# deploy command that:
# 1 syncs s3,
# 2 builds site
# 3 deploys to gh pages with a force push who gaf
