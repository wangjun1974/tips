AWS_ACCESS_KEY=$(oc get secret demo -o jsonpath='{.data.AWS_ACCESS_KEY_ID}{"\n"}' | base64 --decode)
AWS_SECRET_KEY=$(oc get secret demo -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}{"\n"}' | base64 --decode)
BUCKET_HOST=$(oc get route s3 -n openshift-storage -o jsonpath='{.spec.host}{"\n"}')
BUCKET_NAME=$(oc get configmap demo -o jsonpath='{.data.BUCKET_NAME}')
