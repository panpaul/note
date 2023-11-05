set -x
rm -rf themes/cactus
git clone https://github.com/probberechts/hexo-theme-cactus.git themes/cactus
cp themes/_config.yml themes/cactus/
cp themes/diff.patch themes/cactus/
cd themes/cactus && git apply diff.patch && cd ..
npm install
npm install hexo
npx hexo generate
