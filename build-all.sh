cd expected
yarn --silent install
echo
echo '########################################'
echo '## Building the "expected" project... ##'
echo '########################################'
echo
yarn build

cd ..

cd actual
yarn --silent install
echo
echo '######################################'
echo '## Building the "actual" project... ##'
echo '######################################'
echo
yarn build

cd ..
