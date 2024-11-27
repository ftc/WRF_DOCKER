#
#FROM centos:latest - some users reported problems with yum
FROM almalinux:10-kitten
MAINTAINER Dave Gill <gill@ucar.edu>

ENV WRF_VERSION 4.0.3
ENV WPS_VERSION 4.0.2
ENV NML_VERSION 4.0.2

# Set up base OS environment

RUN yum -y update
RUN yum -y install file gcc gcc-gfortran gcc-c++ libpng-devel jasper \
  hostname m4 make perl tar bash tcsh time wget which zlib zlib-devel \
  openssh-clients openssh-server net-tools fontconfig libgfortran libXext libXrender \
  sudo epel-release git

 

# Alternate imagemagick install
RUN dnf install -y epel-release
RUN dnf install -y ImageMagick

# working?
#RUN dnf install -y glibc.i686 
#RUN dnf -y install jasper-devel
#RUN dnf -y install libgcc.i686
#RUN dnf -y install scl

# Newer version of GNU compiler, required for WRF 2003 and 2008 Fortran constructs

### Seems like this may not be needed with newer version of gcc?
#RUN yum -y install centos-release-scl \
#RUN yum -y install devtoolset-8 
#RUN yum -y install devtoolset-8-gcc devtoolset-8-gcc-gfortran devtoolset-8-gcc-c++ 

RUN groupadd wrf -g 9999
RUN useradd -u 9999 -g wrf -G wheel -M -d /wrf wrfuser
RUN mkdir /wrf \
 &&  chown -R wrfuser:wrf /wrf \
 &&  chmod 6755 /wrf

# Build the libraries with a parallel Make
ENV J 4


RUN git clone --recurse-submodules https://github.com/wrf-model/WRF
RUN mkdir WRF/Build_WRF
RUN mkdir WRF/TESTS
RUN cd WRF/TESTS && wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_tests.tar
RUN cd WRF/TESTS && tar -xf Fortran_C_tests.tar
## TODO: automate tests found here and make sure failure fails build: https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php
### manual run of tests seems to work but probably worth automatically testing for future builds

RUN cd WRF/Build_WRF && mkdir LIBRARIES

RUN cd WRF/Build_WRF/LIBRARIES \
 && wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/mpich-3.0.4.tar.gz \
 && wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/netcdf-c-4.7.2.tar.gz \
 && wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/netcdf-fortran-4.5.2.tar.gz \
 && wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz \
 && wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/libpng-1.2.50.tar.gz \
 && wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/zlib-1.2.11.tar.gz

ENV DIR /WRF/Build_WRF/LIBRARIES
ENV CC gcc
ENV CXX g++
ENV FC gfortran
ENV FCFLAGS -m64
ENV F77 gfortran
ENV FFLAGS -m64
ENV JASPERLIB $DIR/grib2/lib
ENV JASPERINC $DIR/grib2/include
ENV LDFLAGS -L$DIR/grib2/lib
ENV CPPFLAGS -I$DIR/grib2/include 

# install netcdf
RUN cd WRF/Build_WRF/LIBRARIES \
 && tar xzvf netcdf-c-4.7.2.tar.gz \
 && cd netcdf-c-4.7.2 \
 && ./configure --prefix=$DIR/netcdf --disable-dap --disable-netcdf-4 --disable-shared

RUN cd WRF/Build_WRF/LIBRARIES/netcdf-c-4.7.2 && make


RUN cd WRF/Build_WRF/LIBRARIES \
 && cd netcdf-c-4.7.2 \
 && make install 

ENV PATH $DIR/netcdf/bin:$PATH
ENV NETCDF $DIR/netcdf 
ENV LIBS "-lnetcdf -lz" \

RUN cd WRF/Build_WRF/LIBRARIES \
 && tar xzvf netcdf-fortran-4.5.2.tar.gz \
 && cd netcdf-fortran-4.5.2 \
 && ./configure --prefix=$DIR/netcdf --disable-dap  --disable-netcdf-4 --disable-shared \
 && make \
 && make install 

ENV PATH $DIR/netcdf/bin:$PATH 
ENV NETCDF $DIR/netcdf



