PY_DIR='temp'
rm -Rf $PY_DIR
poetry install -vvv --no-dev --no-interaction --no-ansi
poetry export -f requirements.txt > requirements.txt --without-hashes
mkdir -p $PY_DIR
mkdir -p $PY_DIR/omfeds_lambda_python
cp omfeds_lambda_python/*.py $PY_DIR/omfeds_lambda_python
cp s3snsoperations.py $PY_DIR
cp snowflake_operations.py $PY_DIR
pip install -r requirements.txt --no-deps -t $PY_DIR
rm -Rf $PY_DIR/__pycache__
rm -Rf $PY_DIR/*/__pycache__
rm -Rf $PY_DIR/*/examples
rm -Rf $PY_DIR/*/test
cd $PY_DIR
zip -r ../omfeds_lambda_python.zip *