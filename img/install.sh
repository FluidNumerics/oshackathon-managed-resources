#!/bin/bash
#
#
# Maintainers : @schoonovernumerics
#
# //////////////////////////////////////////////////////////////// #


sed -i 's#@INSTALL_ROOT@#'"${INSTALL_ROOT}"'#g' ${INSTALL_ROOT}/spack-pkg-env/spack.yaml

if [[ "$COMPILER" == *"intel"* ]]; then
  sed -i 's/@COMPILER@/intel/g' ${INSTALL_ROOT}/spack-pkg-env/spack.yaml
else
  sed -i 's/@COMPILER@/'"${COMPILER}"'/g' ${INSTALL_ROOT}/spack-pkg-env/spack.yaml
fi

source ${INSTALL_ROOT}/spack/share/spack/setup-env.sh

if [[ "$IMAGE_NAME" != "fluid"* ]]; then
   spack install ${COMPILER}
   spack load ${COMPILER}
   spack compiler find --scope site
fi

#spack env activate ${INSTALL_ROOT}/spack-pkg-env/
#spack install --fail-fast --source
#spack gc -y
#spack env deactivate
#spack env activate --sh -d ${INSTALL_ROOT}/spack-pkg-env/ >> /etc/profile.d/z10_spack_environment.sh 


# Update MOTD
cat > /etc/motd << EOL
=======================================================================  
                    Welcome to the OCEAN Cluster
=======================================================================  

  This cluster is a cloud-native HPC cluster with a Slurm job scheduler.

  For support, reach out to support@fluidnumerics.com

=======================================================================  
EOL
