!> \file
!> $Id: CoupledLaplaceExample.f90 20 2007-05-28 20:22:52Z cpb $
!> \author Chris Bradley
!> \brief This is an example program which solves a weakly coupled Laplace equation in two regions using OpenCMISS calls.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is OpenCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s):
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!> \example InterfaceExamples/CoupledLaplace/src/CoupledLaplaceExample.f90
!! Example program which sets up a field in two regions using OpenCMISS calls.
!! \par Latest Builds:
!! \li <a href='http://autotest.bioeng.auckland.ac.nz/opencmiss-build/logs_x86_64-linux/InterfaceExamples/CoupledLaplace/build-intel'>Linux Intel Build</a>
!! \li <a href='http://autotest.bioeng.auckland.ac.nz/opencmiss-build/logs_x86_64-linux/InterfaceExamples/CoupledLaplace/build-gnu'>Linux GNU Build</a>
!<

!> Main program
PROGRAM COUPLEDLAPLACE

  USE OPENCMISS
  
#ifdef WIN32
  USE IFQWIN
#endif

  IMPLICIT NONE

  !Test program parameters

  REAL(CMISSDP), PARAMETER :: HEIGHT=1.0_CMISSDP
  REAL(CMISSDP), PARAMETER :: WIDTH=2.0_CMISSDP
  REAL(CMISSDP), PARAMETER :: LENGTH=3.0_CMISSDP

  INTEGER(CMISSIntg), PARAMETER :: CoordinateSystem1UserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: CoordinateSystem2UserNumber=2
  INTEGER(CMISSIntg), PARAMETER :: Region1UserNumber=3
  INTEGER(CMISSIntg), PARAMETER :: Region2UserNumber=4
  INTEGER(CMISSIntg), PARAMETER :: Basis1UserNumber=5
  INTEGER(CMISSIntg), PARAMETER :: Basis2UserNumber=6
  INTEGER(CMISSIntg), PARAMETER :: InterfaceBasisUserNumber=7
  INTEGER(CMISSIntg), PARAMETER :: GeneratedMesh1UserNumber=8
  INTEGER(CMISSIntg), PARAMETER :: GeneratedMesh2UserNumber=9
  INTEGER(CMISSIntg), PARAMETER :: InterfaceGeneratedMeshUserNumber=10
  INTEGER(CMISSIntg), PARAMETER :: Mesh1UserNumber=11
  INTEGER(CMISSIntg), PARAMETER :: Mesh2UserNumber=12
  INTEGER(CMISSIntg), PARAMETER :: InterfaceMeshUserNumber=13
  INTEGER(CMISSIntg), PARAMETER :: Decomposition1UserNumber=14
  INTEGER(CMISSIntg), PARAMETER :: Decomposition2UserNumber=15
  INTEGER(CMISSIntg), PARAMETER :: InterfaceDecompositionUserNumber=16
  INTEGER(CMISSIntg), PARAMETER :: GeometricField1UserNumber=17
  INTEGER(CMISSIntg), PARAMETER :: GeometricField2UserNumber=18
  INTEGER(CMISSIntg), PARAMETER :: InterfaceGeometricFieldUserNumber=19
  INTEGER(CMISSIntg), PARAMETER :: EquationsSet1UserNumber=20
  INTEGER(CMISSIntg), PARAMETER :: EquationsSet2UserNumber=21
  INTEGER(CMISSIntg), PARAMETER :: DependentField1UserNumber=22
  INTEGER(CMISSIntg), PARAMETER :: DependentField2UserNumber=23
  INTEGER(CMISSIntg), PARAMETER :: InterfaceUserNumber=24
  INTEGER(CMISSIntg), PARAMETER :: InterfaceConditionUserNumber=25
  INTEGER(CMISSIntg), PARAMETER :: LagrangeFieldUserNumber=26
  INTEGER(CMISSIntg), PARAMETER :: CoupledProblemUserNumber=27
  INTEGER(CMISSIntg), PARAMETER :: InterfaceMappingBasisUserNumber=28
 
  !Program types
  
  !Program variables

  INTEGER(CMISSIntg) :: NUMBER_OF_ARGUMENTS,ARGUMENT_LENGTH,STATUS
  INTEGER(CMISSIntg) :: NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS,NUMBER_GLOBAL_Z_ELEMENTS, &
    & INTERPOLATION_TYPE,NUMBER_OF_GAUSS_XI
  CHARACTER(LEN=255) :: COMMAND_ARGUMENT

  INTEGER(CMISSIntg) :: EquationsSet1Index,EquationsSet2Index
  INTEGER(CMISSIntg) :: FirstNodeNumber,LastNodeNumber
  INTEGER(CMISSIntg) :: FirstNodeDomain,LastNodeDomain
  INTEGER(CMISSIntg) :: InterfaceConditionIndex
  INTEGER(CMISSIntg) :: Mesh1Index,Mesh2Index
  INTEGER(CMISSIntg) :: NumberOfComputationalNodes,ComputationalNodeNumber
  INTEGER(CMISSIntg) :: y_element_idx,z_element_idx,mesh_local_y_node,mesh_local_z_node
  REAL(CMISSDP) :: XI2(2),XI3(3)

  !CMISS variables

  TYPE(CMISSBasisType) :: Basis1,Basis2,InterfaceBasis,InterfaceMappingBasis
  TYPE(CMISSBoundaryConditionsType) :: BoundaryConditions1,BoundaryConditions2
  TYPE(CMISSCoordinateSystemType) :: CoordinateSystem1,CoordinateSystem2,WorldCoordinateSystem
  TYPE(CMISSDecompositionType) :: Decomposition1,Decomposition2,InterfaceDecomposition
  TYPE(CMISSEquationsType) :: Equations1,Equations2
  TYPE(CMISSEquationsSetType) :: EquationsSet1,EquationsSet2
  TYPE(CMISSFieldType) :: GeometricField1,GeometricField2,InterfaceGeometricField,DependentField1, &
    & DependentField2,LagrangeField
  TYPE(CMISSFieldsType) :: Fields1,Fields2,InterfaceFields
  TYPE(CMISSGeneratedMeshType) :: GeneratedMesh1,GeneratedMesh2,InterfaceGeneratedMesh
  TYPE(CMISSInterfaceType) :: Interface
  TYPE(CMISSInterfaceConditionType) :: InterfaceCondition
  TYPE(CMISSInterfaceEquationsType) :: InterfaceEquations
  TYPE(CMISSInterfaceMeshConnectivityType) :: InterfaceMeshConnectivity
  TYPE(CMISSMeshType) :: Mesh1,Mesh2,InterfaceMesh
  TYPE(CMISSNodesType) :: Nodes
  TYPE(CMISSProblemType) :: CoupledProblem
  TYPE(CMISSRegionType) :: Region1,Region2,WorldRegion
  TYPE(CMISSSolverType) :: CoupledSolver
  TYPE(CMISSSolverEquationsType) :: CoupledSolverEquations
  
#ifdef WIN32
  !Quickwin type
  LOGICAL :: QUICKWIN_STATUS=.FALSE.
  TYPE(WINDOWCONFIG) :: QUICKWIN_WINDOW_CONFIG
#endif
  
  !Generic CMISS variables
  
  INTEGER(CMISSIntg) :: Err
  
#ifdef WIN32
  !Initialise QuickWin
  QUICKWIN_WINDOW_CONFIG%TITLE="General Output" !Window title
  QUICKWIN_WINDOW_CONFIG%NUMTEXTROWS=-1 !Max possible number of rows
  QUICKWIN_WINDOW_CONFIG%MODE=QWIN$SCROLLDOWN
  !Set the window parameters
  QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
  !If attempt fails set with system estimated values
  IF(.NOT.QUICKWIN_STATUS) QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
#endif

  NUMBER_OF_ARGUMENTS = COMMAND_ARGUMENT_COUNT()
  IF(NUMBER_OF_ARGUMENTS == 4) THEN
    CALL GET_COMMAND_ARGUMENT(1,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 1.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) NUMBER_GLOBAL_X_ELEMENTS
    IF(NUMBER_GLOBAL_X_ELEMENTS<=0) CALL HANDLE_ERROR("Invalid number of X elements.")
    CALL GET_COMMAND_ARGUMENT(2,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 2.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) NUMBER_GLOBAL_Y_ELEMENTS
    IF(NUMBER_GLOBAL_Y_ELEMENTS<=0) CALL HANDLE_ERROR("Invalid number of Y elements.")
    CALL GET_COMMAND_ARGUMENT(3,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 3.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) NUMBER_GLOBAL_Z_ELEMENTS
    IF(NUMBER_GLOBAL_Y_ELEMENTS<0) CALL HANDLE_ERROR("Invalid number of Z elements.")
    CALL GET_COMMAND_ARGUMENT(4,COMMAND_ARGUMENT,ARGUMENT_LENGTH,STATUS)
    IF(STATUS>0) CALL HANDLE_ERROR("Error for command argument 4.")
    READ(COMMAND_ARGUMENT(1:ARGUMENT_LENGTH),*) INTERPOLATION_TYPE
    IF(INTERPOLATION_TYPE<=0.OR.INTERPOLATION_TYPE>3) CALL HANDLE_ERROR("Invalid Interpolation specification.")
  ELSE IF(NUMBER_OF_ARGUMENTS == 0) THEN
    NUMBER_GLOBAL_X_ELEMENTS=2
    NUMBER_GLOBAL_Y_ELEMENTS=2
    NUMBER_GLOBAL_Z_ELEMENTS=0
    INTERPOLATION_TYPE=1
  ELSE
    CALL HANDLE_ERROR("Invalid number of arguments.")
  ENDIF

  !Intialise OpenCMISS
  CALL CMISSInitialise(WorldCoordinateSystem,WorldRegion,Err)

  !Set error handling mode
  CALL CMISSErrorHandlingModeSet(CMISSTrapError,Err)
 
  !Set diganostics for testing
  !CALL CMISSDiagnosticsSetOn(CMISSFromDiagType,[1,2,3,4,5],"Diagnostics",["SOLVER_MAPPING_CALCULATE         ", &
  !  & "SOLVER_MATRIX_STRUCTURE_CALCULATE"],Err)
  
  !Get the computational nodes information
  CALL CMISSComputationalNumberOfNodesGet(NumberOfComputationalNodes,Err)
  CALL CMISSComputationalNodeNumberGet(ComputationalNodeNumber,Err)
  
  !Start the creation of a new RC coordinate system for the first region
  PRINT *, ' == >> CREATING COORDINATE SYSTEM(1) << == '
  CALL CMISSCoordinateSystemTypeInitialise(CoordinateSystem1,Err)
  CALL CMISSCoordinateSystemCreateStart(CoordinateSystem1UserNumber,CoordinateSystem1,Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN
    !Set the coordinate system to be 2D
    CALL CMISSCoordinateSystemDimensionSet(CoordinateSystem1,2,Err)
  ELSE
    !Set the coordinate system to be 3D
    CALL CMISSCoordinateSystemDimensionSet(CoordinateSystem1,3,Err)
  ENDIF
  !Finish the creation of the coordinate system
  CALL CMISSCoordinateSystemCreateFinish(CoordinateSystem1,Err)

  !Start the creation of a new RC coordinate system for the second region
  PRINT *, ' == >> CREATING COORDINATE SYSTEM(2) << == '
  CALL CMISSCoordinateSystemTypeInitialise(CoordinateSystem2,Err)
  CALL CMISSCoordinateSystemCreateStart(CoordinateSystem2UserNumber,CoordinateSystem2,Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN
    !Set the coordinate system to be 2D
    CALL CMISSCoordinateSystemDimensionSet(CoordinateSystem2,2,Err)
  ELSE
    !Set the coordinate system to be 3D
    CALL CMISSCoordinateSystemDimensionSet(CoordinateSystem2,3,Err)
  ENDIF
  !Finish the creation of the coordinate system
  CALL CMISSCoordinateSystemCreateFinish(CoordinateSystem2,Err)
  
  !Start the creation of the first region
  PRINT *, ' == >> CREATING REGION(1) << == '
  CALL CMISSRegionTypeInitialise(Region1,Err)
  CALL CMISSRegionCreateStart(Region1UserNumber,WorldRegion,Region1,Err)
  CALL CMISSRegionLabelSet(Region1,"Region1",Err)
  !Set the regions coordinate system to the RC coordinate system that we have created
  CALL CMISSRegionCoordinateSystemSet(Region1,CoordinateSystem1,Err)
  !Finish the creation of the first region
  CALL CMISSRegionCreateFinish(Region1,Err)

  !Start the creation of the second region
  PRINT *, ' == >> CREATING REGION(2) << == '
  CALL CMISSRegionTypeInitialise(Region2,Err)
  CALL CMISSRegionCreateStart(Region2UserNumber,WorldRegion,Region2,Err)
  CALL CMISSRegionLabelSet(Region2,"Region2",Err)
  !Set the regions coordinate system to the RC coordinate system that we have created
  CALL CMISSRegionCoordinateSystemSet(Region2,CoordinateSystem2,Err)
  !Finish the creation of the second region
  CALL CMISSRegionCreateFinish(Region2,Err)

  !Start the creation of a bI/tri-linear-Lagrange basis
  PRINT *, ' == >> CREATING BASIS(1) << == '
  CALL CMISSBasisTypeInitialise(Basis1,Err)
  CALL CMISSBasisCreateStart(Basis1UserNumber,Basis1,Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN
    !Set the basis to be a bilinear Lagrange basis
    CALL CMISSBasisNumberOfXiSet(Basis1,2,Err)
  ELSE
    !Set the basis to be a trilinear Lagrange basis
    CALL CMISSBasisNumberOfXiSet(Basis1,3,Err)
  ENDIF
  !Finish the creation of the basis
  CALL CMISSBasisCreateFinish(Basis1,Err)
   
  SELECT CASE(INTERPOLATION_TYPE)
  CASE(1)
    NUMBER_OF_GAUSS_XI=2
  CASE(2)
    NUMBER_OF_GAUSS_XI=3
  CASE(3,4)
    NUMBER_OF_GAUSS_XI=4
  CASE DEFAULT
    CALL HANDLE_ERROR("Invalid interpolation type.")
  END SELECT
  !Start the creation of a bI/tri-XXX-Lagrange basis
  PRINT *, ' == >> CREATING BASIS(2) << == '
  CALL CMISSBasisTypeInitialise(Basis2,Err)
  CALL CMISSBasisCreateStart(Basis2UserNumber,Basis2,Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN
    !Set the basis to be a bi-XXX Lagrange basis
    CALL CMISSBasisNumberOfXiSet(Basis2,2,Err)
    CALL CMISSBasisInterpolationXiSet(Basis2,[INTERPOLATION_TYPE,INTERPOLATION_TYPE],Err)
    CALL CMISSBasisQuadratureNumberOfGaussXiSet(Basis2,[NUMBER_OF_GAUSS_XI,NUMBER_OF_GAUSS_XI],Err)
  ELSE
    !Set the basis to be a tri-XXX Lagrange basis
    CALL CMISSBasisNumberOfXiSet(Basis2,3,Err)
    CALL CMISSBasisInterpolationXiSet(Basis2,[INTERPOLATION_TYPE,INTERPOLATION_TYPE,INTERPOLATION_TYPE],Err)
    CALL CMISSBasisQuadratureNumberOfGaussXiSet(Basis2,[NUMBER_OF_GAUSS_XI,NUMBER_OF_GAUSS_XI, &
      & NUMBER_OF_GAUSS_XI],Err)
  ENDIF
  !Finish the creation of the basis
  CALL CMISSBasisCreateFinish(Basis2,Err)
  
  !Start the creation of a generated mesh in the first region
  PRINT *, ' == >> CREATING GENERATED MESH(1) << == '
  CALL CMISSGeneratedMeshTypeInitialise(GeneratedMesh1,Err)
  CALL CMISSGeneratedMeshCreateStart(GeneratedMesh1UserNumber,Region1,GeneratedMesh1,Err)
  !Set up a regular x*y*z mesh
  CALL CMISSGeneratedMeshTypeSet(GeneratedMesh1,CMISSGeneratedMeshRegularMeshType,Err)
  !Set the default basis
  CALL CMISSGeneratedMeshBasisSet(GeneratedMesh1,Basis1,Err)   
  !Define the mesh on the first region
  IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN
    CALL CMISSGeneratedMeshExtentSet(GeneratedMesh1,[WIDTH,HEIGHT],Err)
    CALL CMISSGeneratedMeshNumberOfElementsSet(GeneratedMesh1,[NUMBER_GLOBAL_X_ELEMENTS, &
      & NUMBER_GLOBAL_Y_ELEMENTS],Err)
  ELSE
    CALL CMISSGeneratedMeshExtentSet(GeneratedMesh1,[WIDTH,HEIGHT,LENGTH],Err)
    CALL CMISSGeneratedMeshNumberOfElementsSet(GeneratedMesh1,[NUMBER_GLOBAL_X_ELEMENTS, &
      & NUMBER_GLOBAL_Y_ELEMENTS,NUMBER_GLOBAL_Z_ELEMENTS],Err)
  ENDIF    
  !Finish the creation of a generated mesh in the first region
  CALL CMISSMeshTypeInitialise(Mesh1,Err)
  CALL CMISSGeneratedMeshCreateFinish(GeneratedMesh1,Mesh1UserNumber,Mesh1,Err)

  !Start the creation of a generated mesh in the second region
  PRINT *, ' == >> CREATING GENERATED MESH(2) << == '
  CALL CMISSGeneratedMeshTypeInitialise(GeneratedMesh2,Err)
  CALL CMISSGeneratedMeshCreateStart(GeneratedMesh2UserNumber,Region2,GeneratedMesh2,Err)
  !Set up a regular x*y*z mesh
  CALL CMISSGeneratedMeshTypeSet(GeneratedMesh2,CMISSGeneratedMeshRegularMeshType,Err)
  !Set the default basis
  CALL CMISSGeneratedMeshBasisSet(GeneratedMesh2,Basis2,Err)   
  !Define the mesh on the second region
  IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN
    CALL CMISSGeneratedMeshOriginSet(GeneratedMesh2,[WIDTH,0.0_CMISSDP],Err)
    CALL CMISSGeneratedMeshExtentSet(GeneratedMesh2,[WIDTH,HEIGHT],Err)
    CALL CMISSGeneratedMeshNumberOfElementsSet(GeneratedMesh2,[NUMBER_GLOBAL_X_ELEMENTS, &
      & NUMBER_GLOBAL_Y_ELEMENTS],Err)
  ELSE
    CALL CMISSGeneratedMeshOriginSet(GeneratedMesh2,[WIDTH,0.0_CMISSDP,0.0_CMISSDP],Err)
    CALL CMISSGeneratedMeshExtentSet(GeneratedMesh2,[WIDTH,HEIGHT,LENGTH],Err)
    CALL CMISSGeneratedMeshNumberOfElementsSet(GeneratedMesh2,[NUMBER_GLOBAL_X_ELEMENTS, &
      & NUMBER_GLOBAL_Y_ELEMENTS,NUMBER_GLOBAL_Z_ELEMENTS],Err)
  ENDIF    
  !Finish the creation of a generated mesh in the second region
  CALL CMISSMeshTypeInitialise(Mesh2,Err)
  CALL CMISSGeneratedMeshCreateFinish(GeneratedMesh2,Mesh2UserNumber,Mesh2,Err)

  !Create an interface between the two meshes
  PRINT *, ' == >> CREATING INTERFACE << == '
  CALL CMISSInterfaceTypeInitialise(Interface,Err)
  CALL CMISSInterfaceCreateStart(InterfaceUserNumber,WorldRegion,Interface,Err)
  CALL CMISSInterfaceLabelSet(Interface,"Interface",Err)
  !Add in the two meshes
  CALL CMISSInterfaceMeshAdd(Interface,Mesh1,Mesh1Index,Err)
  CALL CMISSInterfaceMeshAdd(Interface,Mesh2,Mesh2Index,Err)
  !Finish creating the interface
  CALL CMISSInterfaceCreateFinish(Interface,Err)

  !Start the creation of a (bi)-linear-Lagrange basis
  PRINT *, ' == >> CREATING INTERFACE BASIS << == '
  CALL CMISSBasisTypeInitialise(InterfaceBasis,Err)
  CALL CMISSBasisCreateStart(InterfaceBasisUserNumber,InterfaceBasis,Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN  
    !Set the basis to be a linear Lagrange basis
    CALL CMISSBasisNumberOfXiSet(InterfaceBasis,1,Err)
    CALL CMISSBasisInterpolationXiSet(InterfaceBasis,[CMISSBasisLinearLagrangeInterpolation],Err)
  ELSE
    !Set the basis to be a bilinear Lagrange basis
    CALL CMISSBasisNumberOfXiSet(InterfaceBasis,2,Err)
    CALL CMISSBasisInterpolationXiSet(InterfaceBasis,[CMISSBasisLinearLagrangeInterpolation, &
      & CMISSBasisLinearLagrangeInterpolation],Err)
  ENDIF
  !Finish the creation of the basis
  CALL CMISSBasisCreateFinish(InterfaceBasis,Err)

  !Start the creation of a (bi)-linear-Lagrange basis
  PRINT *, ' == >> CREATING INTERFACE MAPPING BASIS << == '
  CALL CMISSBasisTypeInitialise(InterfaceMappingBasis,Err)
  CALL CMISSBasisCreateStart(InterfaceMappingBasisUserNumber,InterfaceMappingBasis,Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN  
    !Set the basis to be a linear Lagrange basis
    CALL CMISSBasisNumberOfXiSet(InterfaceMappingBasis,1,Err)
    CALL CMISSBasisInterpolationXiSet(InterfaceMappingBasis,[CMISSBasisLinearLagrangeInterpolation],Err)
    CALL CMISSBasisQuadratureNumberOfGaussXiSet(InterfaceMappingBasis,[INTERPOLATION_TYPE+1],Err)
  ELSE
    !Set the basis to be a bilinear Lagrange basis
    CALL CMISSBasisNumberOfXiSet(InterfaceMappingBasis,2,Err)
    CALL CMISSBasisInterpolationXiSet(InterfaceMappingBasis,[CMISSBasisLinearLagrangeInterpolation, &
      & CMISSBasisLinearLagrangeInterpolation],Err)
    CALL CMISSBasisQuadratureNumberOfGaussXiSet(InterfaceMappingBasis,[INTERPOLATION_TYPE+1, &
      & INTERPOLATION_TYPE+1],Err)
  ENDIF
  !Finish the creation of the basis
  CALL CMISSBasisCreateFinish(InterfaceMappingBasis,Err)
  
  !Start the creation of a generated mesh for the interface
  PRINT *, ' == >> CREATING INTERFACE GENERATED MESH << == '
  CALL CMISSGeneratedMeshTypeInitialise(InterfaceGeneratedMesh,Err)
  CALL CMISSGeneratedMeshCreateStart(InterfaceGeneratedMeshUserNumber,Interface,InterfaceGeneratedMesh,Err)
  !Set up a regular x*y*z mesh
  CALL CMISSGeneratedMeshTypeSet(InterfaceGeneratedMesh,CMISSGeneratedMeshRegularMeshType,Err)
  !Set the default basis
  CALL CMISSGeneratedMeshBasisSet(InterfaceGeneratedMesh,InterfaceBasis,Err)   
  !Define the mesh on the interface
  CALL CMISSGeneratedMeshOriginSet(InterfaceGeneratedMesh,[WIDTH,0.0_CMISSDP,0.0_CMISSDP],Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN
    CALL CMISSGeneratedMeshExtentSet(InterfaceGeneratedMesh,[0.0_CMISSDP,HEIGHT,0.0_CMISSDP],Err)
    CALL CMISSGeneratedMeshNumberOfElementsSet(InterfaceGeneratedMesh,[NUMBER_GLOBAL_Y_ELEMENTS],Err)
  ELSE
    CALL CMISSGeneratedMeshExtentSet(InterfaceGeneratedMesh,[0.0_CMISSDP,HEIGHT,LENGTH],Err)
    CALL CMISSGeneratedMeshNumberOfElementsSet(InterfaceGeneratedMesh,[NUMBER_GLOBAL_Y_ELEMENTS, &
      & NUMBER_GLOBAL_Z_ELEMENTS],Err)
  ENDIF    
  !Finish the creation of a generated mesh in interface
  CALL CMISSMeshTypeInitialise(InterfaceMesh,Err)
  CALL CMISSGeneratedMeshCreateFinish(InterfaceGeneratedMesh,InterfaceMeshUserNumber,InterfaceMesh,Err)

  !Couple the interface meshes
  PRINT *, ' == >> CREATING INTERFACE MESHES CONNECTIVITY << == '
  CALL CMISSInterfaceMeshConnectivityTypeInitialise(InterfaceMeshConnectivity,Err)
  CALL CMISSInterfaceMeshConnectivityCreateStart(Interface,InterfaceMesh,InterfaceMeshConnectivity,Err)
  CALL CMISSInterfaceMeshConnectivitySetBasis(InterfaceMeshConnectivity,InterfaceMappingBasis,Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN
    DO y_element_idx=1,NUMBER_GLOBAL_Y_ELEMENTS
      !Map the interface element to the elements in mesh 1
      CALL CMISSInterfaceMeshConnectivityElementNumberSet(InterfaceMeshConnectivity,y_element_idx,Mesh1Index, &
        y_element_idx*NUMBER_GLOBAL_X_ELEMENTS,Err)
      XI2 = [ 1.0_CMISSDP, 0.0_CMISSDP ]
      CALL CMISSInterfaceMeshConnectivityElementXiSet(InterfaceMeshConnectivity,y_element_idx,Mesh1Index, &
        & y_element_idx*NUMBER_GLOBAL_X_ELEMENTS,1,1,XI2,Err)
      XI2 = [ 1.0_CMISSDP, 1.0_CMISSDP ]
      CALL CMISSInterfaceMeshConnectivityElementXiSet(InterfaceMeshConnectivity,y_element_idx,Mesh1Index, &
        & y_element_idx*NUMBER_GLOBAL_X_ELEMENTS,2,1,XI2,Err)      
      !Map the interface element to the elements in mesh 2
      CALL CMISSInterfaceMeshConnectivityElementNumberSet(InterfaceMeshConnectivity,y_element_idx,Mesh2Index, &
        & 1+(y_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS,Err)
      DO mesh_local_y_node = 1,INTERPOLATION_TYPE
        XI2 = [ 0.0_CMISSDP, REAL(mesh_local_y_node-1,CMISSDP)/REAL(INTERPOLATION_TYPE,CMISSDP) ]
        CALL CMISSInterfaceMeshConnectivityElementXiSet(InterfaceMeshConnectivity,y_element_idx,Mesh2Index, &
          & 1+(y_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS,1,1,XI2,Err)
        XI2 = [ 0.0_CMISSDP, REAL(mesh_local_y_node,CMISSDP)/REAL(INTERPOLATION_TYPE,CMISSDP) ]
        CALL CMISSInterfaceMeshConnectivityElementXiSet(InterfaceMeshConnectivity,y_element_idx,Mesh2Index, &
          & 1+(y_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS,2,1,XI2,Err)
      ENDDO !mesh_local_y_node
    ENDDO !y_element_idx
  ELSE
    DO y_element_idx=1,NUMBER_GLOBAL_Y_ELEMENTS
      DO z_element_idx=1,NUMBER_GLOBAL_Z_ELEMENTS
        !Map the interface element to the elements in mesh 1
        CALL CMISSInterfaceMeshConnectivityElementNumberSet(InterfaceMeshConnectivity, &
          & y_element_idx+(z_element_idx-1)*NUMBER_GLOBAL_Y_ELEMENTS,Mesh1Index, &
          y_element_idx*NUMBER_GLOBAL_X_ELEMENTS+(z_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS* &
          & NUMBER_GLOBAL_Y_ELEMENTS,Err)
        XI3 = [ 1.0_CMISSDP, 0.0_CMISSDP, 0.0_CMISSDP ]
        CALL CMISSInterfaceMeshConnectivityElementXiSet(InterfaceMeshConnectivity,y_element_idx+ &
          & (z_element_idx-1)*NUMBER_GLOBAL_Y_ELEMENTS,Mesh1Index,y_element_idx* &
          & NUMBER_GLOBAL_X_ELEMENTS+(z_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS* &
          & NUMBER_GLOBAL_Y_ELEMENTS,1,1,XI3,Err)
        XI3 = [ 1.0_CMISSDP, 1.0_CMISSDP, 0.0_CMISSDP ]
        CALL CMISSInterfaceMeshConnectivityElementXiSet(InterfaceMeshConnectivity,y_element_idx+ &
          & (z_element_idx-1)*NUMBER_GLOBAL_Y_ELEMENTS,Mesh1Index,y_element_idx* &
          & NUMBER_GLOBAL_X_ELEMENTS+(z_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS* &
          & NUMBER_GLOBAL_Y_ELEMENTS,2,1,XI3,Err)
        XI3 = [ 1.0_CMISSDP, 0.0_CMISSDP, 1.0_CMISSDP ]
        CALL CMISSInterfaceMeshConnectivityElementXiSet(InterfaceMeshConnectivity,y_element_idx+ &
          & (z_element_idx-1)*NUMBER_GLOBAL_Y_ELEMENTS,Mesh1Index,y_element_idx* &
          & NUMBER_GLOBAL_X_ELEMENTS+(z_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS* &
          & NUMBER_GLOBAL_Y_ELEMENTS,3,1,XI3,Err)
        XI3 = [ 1.0_CMISSDP, 1.0_CMISSDP, 1.0_CMISSDP ]
        CALL CMISSInterfaceMeshConnectivityElementXiSet(InterfaceMeshConnectivity,y_element_idx+ &
          & (z_element_idx-1)*NUMBER_GLOBAL_Y_ELEMENTS,Mesh1Index,y_element_idx* &
          & NUMBER_GLOBAL_X_ELEMENTS+(z_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS* &
          & NUMBER_GLOBAL_Y_ELEMENTS,4,1,XI3,Err)
        !Map the interface element to the elements in mesh 2
        CALL CMISSInterfaceMeshConnectivityElementNumberSet(InterfaceMeshConnectivity,y_element_idx,Mesh2Index, &
          & 1+(y_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS,Err)
        DO mesh_local_y_node = 1,INTERPOLATION_TYPE
          DO mesh_local_z_node = 1,INTERPOLATION_TYPE
            XI3 = [ 0.0_CMISSDP,  &
              & REAL(mesh_local_y_node-1,CMISSDP)/REAL(INTERPOLATION_TYPE,CMISSDP), &
              & REAL(mesh_local_z_node-1,CMISSDP)/REAL(INTERPOLATION_TYPE,CMISSDP) ]
            CALL CMISSInterfaceMeshConnectivityElementXiSet(InterfaceMeshConnectivity,y_element_idx+ &
              & (z_element_idx-1)*NUMBER_GLOBAL_Y_ELEMENTS,Mesh2Index,y_element_idx* &
              & NUMBER_GLOBAL_X_ELEMENTS+(z_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS* &
              & NUMBER_GLOBAL_Y_ELEMENTS,1,1,XI3,Err)
            XI3 = [ 0.0_CMISSDP,  &
              & REAL(mesh_local_y_node,CMISSDP)/REAL(INTERPOLATION_TYPE,CMISSDP), &
              & REAL(mesh_local_z_node-1,CMISSDP)/REAL(INTERPOLATION_TYPE,CMISSDP) ]
            CALL CMISSInterfaceMeshConnectivityElementXiSet(InterfaceMeshConnectivity,y_element_idx+ &
              & (z_element_idx-1)*NUMBER_GLOBAL_Y_ELEMENTS,Mesh2Index,y_element_idx* &
              & NUMBER_GLOBAL_X_ELEMENTS+(z_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS* &
              & NUMBER_GLOBAL_Y_ELEMENTS,2,1,XI3,Err)
            XI3 = [ 0.0_CMISSDP,  &
              & REAL(mesh_local_y_node-1,CMISSDP)/REAL(INTERPOLATION_TYPE,CMISSDP), &
              & REAL(mesh_local_z_node,CMISSDP)/REAL(INTERPOLATION_TYPE,CMISSDP) ]
            CALL CMISSInterfaceMeshConnectivityElementXiSet(InterfaceMeshConnectivity,y_element_idx+ &
              & (z_element_idx-1)*NUMBER_GLOBAL_Y_ELEMENTS,Mesh2Index,y_element_idx* &
              & NUMBER_GLOBAL_X_ELEMENTS+(z_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS* &
              & NUMBER_GLOBAL_Y_ELEMENTS,3,1,XI3,Err)
            XI3 = [ 0.0_CMISSDP,  &
              & REAL(mesh_local_y_node,CMISSDP)/REAL(INTERPOLATION_TYPE,CMISSDP), &
              & REAL(mesh_local_z_node,CMISSDP)/REAL(INTERPOLATION_TYPE,CMISSDP) ]
            CALL CMISSInterfaceMeshConnectivityElementXiSet(InterfaceMeshConnectivity,y_element_idx+ &
              & (z_element_idx-1)*NUMBER_GLOBAL_Y_ELEMENTS,Mesh2Index,y_element_idx* &
              & NUMBER_GLOBAL_X_ELEMENTS+(z_element_idx-1)*NUMBER_GLOBAL_X_ELEMENTS* &
              & NUMBER_GLOBAL_Y_ELEMENTS,4,1,XI3,Err)
          ENDDO !mesh_local_z_node
        ENDDO !mesh_local_y_node
      ENDDO !z_element_idx
    ENDDO !y_element_idx
  ENDIF
  CALL CMISSInterfaceMeshConnectivityCreateFinish(InterfaceMeshConnectivity,Err)

  !Create a decomposition for mesh1
  PRINT *, ' == >> CREATING MESH(1) DECOMPOSITION << == '
  CALL CMISSDecompositionTypeInitialise(Decomposition1,Err)
  CALL CMISSDecompositionCreateStart(Decomposition1UserNumber,Mesh1,Decomposition1,Err)
  !Set the decomposition to be a general decomposition with the specified number of domains
  CALL CMISSDecompositionTypeSet(Decomposition1,CMISSDecompositionCalculatedType,Err)
  CALL CMISSDecompositionNumberOfDomainsSet(Decomposition1,NumberOfComputationalNodes,Err)
  !Finish the decomposition
  CALL CMISSDecompositionCreateFinish(Decomposition1,Err)

  !Create a decomposition for mesh2
  PRINT *, ' == >> CREATING MESH(2) DECOMPOSITION << == '
  CALL CMISSDecompositionTypeInitialise(Decomposition2,Err)
  CALL CMISSDecompositionCreateStart(Decomposition2UserNumber,Mesh2,Decomposition2,Err)
  !Set the decomposition to be a general decomposition with the specified number of domains
  CALL CMISSDecompositionTypeSet(Decomposition2,CMISSDecompositionCalculatedType,Err)
  CALL CMISSDecompositionNumberOfDomainsSet(Decomposition2,NumberOfComputationalNodes,Err)
  !Finish the decomposition
  CALL CMISSDecompositionCreateFinish(Decomposition2,Err)
  
  !Create a decomposition for the interface mesh
  PRINT *, ' == >> CREATING INTERFACE DECOMPOSITION << == '
  CALL CMISSDecompositionTypeInitialise(InterfaceDecomposition,Err)
  CALL CMISSDecompositionCreateStart(InterfaceDecompositionUserNumber,InterfaceMesh,InterfaceDecomposition,Err)
  !Set the decomposition to be a general decomposition with the specified number of domains
  CALL CMISSDecompositionTypeSet(InterfaceDecomposition,CMISSDecompositionCalculatedType,Err)
  CALL CMISSDecompositionNumberOfDomainsSet(InterfaceDecomposition,NumberOfComputationalNodes,Err)
  !Finish the decomposition
  CALL CMISSDecompositionCreateFinish(InterfaceDecomposition,Err)

  !Start to create a default (geometric) field on the first region
  PRINT *, ' == >> CREATING MESH(1) GEOMETRIC FIELD << == '
  CALL CMISSFieldTypeInitialise(GeometricField1,Err)
  CALL CMISSFieldCreateStart(GeometricField1UserNumber,Region1,GeometricField1,Err)
  !Set the decomposition to use
  CALL CMISSFieldMeshDecompositionSet(GeometricField1,Decomposition1,Err)
  !Set the domain to be used by the field components.
  CALL CMISSFieldComponentMeshComponentSet(GeometricField1,CMISSFieldUVariableType,1,1,Err)
  CALL CMISSFieldComponentMeshComponentSet(GeometricField1,CMISSFieldUVariableType,2,1,Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS/=0) THEN
    CALL CMISSFieldComponentMeshComponentSet(GeometricField1,CMISSFieldUVariableType,3,1,Err)
  ENDIF
  !Finish creating the first field
  CALL CMISSFieldCreateFinish(GeometricField1,Err)

  !Start to create a default (geometric) field on the second region
  PRINT *, ' == >> CREATING MESH(2) GEOMETRIC FIELD << == '
  CALL CMISSFieldTypeInitialise(GeometricField2,Err)
  CALL CMISSFieldCreateStart(GeometricField2UserNumber,Region2,GeometricField2,Err)
  !Set the decomposition to use
  CALL CMISSFieldMeshDecompositionSet(GeometricField2,Decomposition2,Err)
  !Set the domain to be used by the field components.
  CALL CMISSFieldComponentMeshComponentSet(GeometricField2,CMISSFieldUVariableType,1,1,Err)
  CALL CMISSFieldComponentMeshComponentSet(GeometricField2,CMISSFieldUVariableType,2,1,Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS/=0) THEN
    CALL CMISSFieldComponentMeshComponentSet(GeometricField2,CMISSFieldUVariableType,3,1,Err)
  ENDIF
  !Finish creating the second field
  CALL CMISSFieldCreateFinish(GeometricField2,Err)

  !Update the geometric field parameters for the first field
  CALL CMISSGeneratedMeshGeometricParametersCalculate(GeometricField1,GeneratedMesh1,Err)
  !Update the geometric field parameters for the second field
  CALL CMISSGeneratedMeshGeometricParametersCalculate(GeometricField2,GeneratedMesh2,Err)

  !Create the equations set for the first region
  PRINT *, ' == >> CREATING EQUATION SET(1) << == '
  CALL CMISSEquationsSetTypeInitialise(EquationsSet1,Err)
  CALL CMISSEquationsSetCreateStart(EquationsSet1UserNumber,Region1,GeometricField1,EquationsSet1,Err)
  !Set the equations set to be a standard Laplace problem
  CALL CMISSEquationsSetSpecificationSet(EquationsSet1,CMISSEquationsSetClassicalFieldClass, &
    & CMISSEquationsSetLaplaceEquationType,CMISSEquationsSetStandardLaplaceSubtype,Err)
  !Finish creating the equations set
  CALL CMISSEquationsSetCreateFinish(EquationsSet1,Err)

  !Create the equations set for the second region
  PRINT *, ' == >> CREATING EQUATION SET(2) << == '
  CALL CMISSEquationsSetTypeInitialise(EquationsSet2,Err)
  CALL CMISSEquationsSetCreateStart(EquationsSet2UserNumber,Region2,GeometricField2,EquationsSet2,Err)
  !Set the equations set to be a standard Laplace problem
  CALL CMISSEquationsSetSpecificationSet(EquationsSet2,CMISSEquationsSetClassicalFieldClass, &
    & CMISSEquationsSetLaplaceEquationType,CMISSEquationsSetStandardLaplaceSubtype,Err)
  !Finish creating the equations set
  CALL CMISSEquationsSetCreateFinish(EquationsSet2,Err)

  !Create the equations set dependent field variables for the first equations set
  PRINT *, ' == >> CREATING DEPENDENT FIELD(1) << == '
  CALL CMISSFieldTypeInitialise(DependentField1,Err)
  CALL CMISSEquationsSetDependentCreateStart(EquationsSet1,DependentField1UserNumber,DependentField1,Err)
  !Finish the equations set dependent field variables
  CALL CMISSEquationsSetDependentCreateFinish(EquationsSet1,Err)

  !Create the equations set dependent field variables for the second equations set
  PRINT *, ' == >> CREATING DEPENDENT FIELD(2) << == '
  CALL CMISSFieldTypeInitialise(DependentField2,Err)
  CALL CMISSEquationsSetDependentCreateStart(EquationsSet2,DependentField2UserNumber,DependentField2,Err)
  !Finish the equations set dependent field variables
  CALL CMISSEquationsSetDependentCreateFinish(EquationsSet2,Err)

  !Create the equations set equations for the first equations set
  PRINT *, ' == >> CREATING EQUATIONS(1) << == '
  CALL CMISSEquationsTypeInitialise(Equations1,Err)
  CALL CMISSEquationsSetEquationsCreateStart(EquationsSet1,Equations1,Err)
  !Set the equations matrices sparsity type
  CALL CMISSEquationsSparsityTypeSet(Equations1,CMISSEquationsSparseMatrices,Err)
  !Set the equations set output
  !CALL CMISSEquationsOutputTypeSet(Equations1,CMISSEquationsNoOutput,Err)
  CALL CMISSEquationsOutputTypeSet(Equations1,CMISSEquationsTimingOutput,Err)
  !CALL CMISSEquationsOutputTypeSet(Equations1,CMISSEquationsMatrixOutput,Err)
  !CALL CMISSEquationsOutputTypeSet(Equations1,CMISSEquationsElementMatrixOutput,Err)
  !Finish the equations set equations
  CALL CMISSEquationsSetEquationsCreateFinish(EquationsSet1,Err)

  !Create the equations set equations for the second equations set
  PRINT *, ' == >> CREATING EQUATIONS(2) << == '
  CALL CMISSEquationsTypeInitialise(Equations2,Err)
  CALL CMISSEquationsSetEquationsCreateStart(EquationsSet2,Equations2,Err)
  !Set the equations matrices sparsity type
  CALL CMISSEquationsSparsityTypeSet(Equations2,CMISSEquationsSparseMatrices,Err)
  !Set the equations set output
  !CALL CMISSEquationsOutputTypeSet(Equations2,CMISSEquationsNoOutput,Err)
  CALL CMISSEquationsOutputTypeSet(Equations2,CMISSEquationsTimingOutput,Err)
  !CALL CMISSEquationsOutputTypeSet(Equations2,CMISSEquationsMatrixOutput,Err)
  !CALL CMISSEquationsOutputTypeSet(Equations2,CMISSEquationsElementMatrixOutput,Err)
  !Finish the equations set equations
  CALL CMISSEquationsSetEquationsCreateFinish(EquationsSet2,Err)

  !Start the creation of the equations set boundary conditions for the first equations set
  PRINT *, ' == >> CREATING BOUNDARY CONDITIONS(1) << == '
  CALL CMISSBoundaryConditionsTypeInitialise(BoundaryConditions1,Err)
  CALL CMISSEquationsSetBoundaryConditionsCreateStart(EquationsSet1,BoundaryConditions1,Err)
  !Set the first node to 0.0
  FirstNodeNumber=1
  CALL CMISSDecompositionNodeDomainGet(Decomposition1,FirstNodeNumber,1,FirstNodeDomain,Err)
  IF(FirstNodeDomain==ComputationalNodeNumber) THEN
    CALL CMISSBoundaryConditionsSetNode(BoundaryConditions1,CMISSFieldUVariableType,1,FirstNodeNumber,1, &
      & CMISSBoundaryConditionFixed,0.0_CMISSDP,Err)
  ENDIF
  !Finish the creation of the equations set boundary conditions
  CALL CMISSEquationsSetBoundaryConditionsCreateFinish(EquationsSet1,Err)
  
  !Start the creation of the equations set boundary conditions for the second equations set
  PRINT *, ' == >> CREATING BOUNDARY CONDITIONS(2) << == '
  CALL CMISSBoundaryConditionsTypeInitialise(BoundaryConditions2,Err)
  CALL CMISSEquationsSetBoundaryConditionsCreateStart(EquationsSet2,BoundaryConditions2,Err)
  !Set the last node to 1.0
  CALL CMISSNodesTypeInitialise(Nodes,Err)
  CALL CMISSRegionNodesGet(Region2,Nodes,Err)
  CALL CMISSNodesNumberOfNodesGet(Nodes,LastNodeNumber,Err)
  CALL CMISSDecompositionNodeDomainGet(Decomposition2,LastNodeNumber,1,LastNodeDomain,Err)
  IF(LastNodeDomain==ComputationalNodeNumber) THEN
    CALL CMISSBoundaryConditionsSetNode(BoundaryConditions2,CMISSFieldUVariableType,1,LastNodeNumber,1, &
      & CMISSBoundaryConditionFixed,1.0_CMISSDP,Err)
  ENDIF
  !Finish the creation of the equations set boundary conditions
  CALL CMISSEquationsSetBoundaryConditionsCreateFinish(EquationsSet2,Err)

  !Start to create a default (geometric) field on the Interface
  PRINT *, ' == >> CREATING INTERFACE GEOMETRIC FIELD << == '
  CALL CMISSFieldTypeInitialise(InterfaceGeometricField,Err)
  CALL CMISSFieldCreateStart(InterfaceGeometricFieldUserNumber,Interface,InterfaceGeometricField,Err)
  !Set the decomposition to use
  CALL CMISSFieldMeshDecompositionSet(InterfaceGeometricField,InterfaceDecomposition,Err)
  !Set the domain to be used by the field components.
  CALL CMISSFieldComponentMeshComponentSet(InterfaceGeometricField,CMISSFieldUVariableType,1,1,Err)
  CALL CMISSFieldComponentMeshComponentSet(InterfaceGeometricField,CMISSFieldUVariableType,2,1,Err)
  IF(NUMBER_GLOBAL_Z_ELEMENTS/=0) THEN
    CALL CMISSFieldComponentMeshComponentSet(InterfaceGeometricField,CMISSFieldUVariableType,3,1,Err)
  ENDIF
  !Finish creating the first field
  CALL CMISSFieldCreateFinish(InterfaceGeometricField,Err)

  !Update the geometric field parameters for the interface field
  CALL CMISSGeneratedMeshGeometricParametersCalculate(InterfaceGeometricField,InterfaceGeneratedMesh,Err)

  !Create an interface condition between the two meshes
  PRINT *, ' == >> CREATING INTERFACE CONDITIONS << == '
  CALL CMISSInterfaceConditionTypeInitialise(InterfaceCondition,Err)
  CALL CMISSInterfaceConditionCreateStart(InterfaceConditionUserNumber,Interface,InterfaceGeometricField, &
    & InterfaceCondition,Err)
  !Specify the method for the interface condition
  CALL CMISSInterfaceConditionMethodSet(InterfaceCondition,CMISSInterfaceConditionLagrangeMultipliers,Err)
  !Specify the type of interface condition operator
  CALL CMISSInterfaceConditionOperatorSet(InterfaceCondition,CMISSInterfaceConditionFieldContinuityOperator,Err)
  !Add in the dependent variables from the equations sets
  CALL CMISSInterfaceConditionDependentVariableAdd(InterfaceCondition,Mesh1Index,EquationsSet1, &
    & CMISSFieldUVariableType,Err)
  CALL CMISSInterfaceConditionDependentVariableAdd(InterfaceCondition,Mesh2Index,EquationsSet2, &
    & CMISSFieldUVariableType,Err)
  !Finish creating the interface condition
  CALL CMISSInterfaceConditionCreateFinish(InterfaceCondition,Err)

  !Create the Lagrange multipliers field
  PRINT *, ' == >> CREATING INTERFACE LAGRANGE FIELD << == '
  CALL CMISSFieldTypeInitialise(LagrangeField,Err)
  CALL CMISSInterfaceConditionLagrangeFieldCreateStart(InterfaceCondition,LagrangeFieldUserNumber,LagrangeField,Err)
  !Finish the Lagrange multipliers field
  CALL CMISSInterfaceConditionLagrangeFieldCreateFinish(InterfaceCondition,Err)

  !Create the interface condition equations
  PRINT *, ' == >> CREATING INTERFACE EQUATIONS << == '
  CALL CMISSInterfaceEquationsTypeInitialise(InterfaceEquations,Err)
  CALL CMISSInterfaceConditionEquationsCreateStart(InterfaceCondition,InterfaceEquations,Err)
  !Set the interface equations sparsity
  CALL CMISSInterfaceEquationsSparsitySet(InterfaceEquations,CMISSEquationsSparseMatrices,Err)
  !Set the interface equations output
  CALL CMISSInterfaceEquationsOutputTypeSet(InterfaceEquations,CMISSEquationsMatrixOutput,Err)
  !Finish creating the interface equations
  CALL CMISSInterfaceConditionEquationsCreateFinish(InterfaceCondition,Err)
  
  !Start the creation of a coupled problem.
  PRINT *, ' == >> CREATING PROBLEM << == '
  CALL CMISSProblemTypeInitialise(CoupledProblem,Err)
  CALL CMISSProblemCreateStart(CoupledProblemUserNumber,CoupledProblem,Err)
  !Set the problem to be a standard Laplace problem
  CALL CMISSProblemSpecificationSet(CoupledProblem,CMISSProblemClassicalFieldClass, &
    & CMISSProblemLaplaceEquationType,CMISSProblemStandardLaplaceSubtype,Err)
  !Finish the creation of a problem.
  CALL CMISSProblemCreateFinish(CoupledProblem,Err)

  !Start the creation of the problem control loop for the coupled problem
  PRINT *, ' == >> CREATING PROBLEM CONTROL LOOP << == '
  CALL CMISSProblemControlLoopCreateStart(CoupledProblem,Err)
  !Finish creating the problem control loop
  CALL CMISSProblemControlLoopCreateFinish(CoupledProblem,Err)
 
  !Start the creation of the problem solver for the coupled problem
  PRINT *, ' == >> CREATING PROBLEM SOLVERS << == '
  CALL CMISSSolverTypeInitialise(CoupledSolver,Err)
  CALL CMISSProblemSolversCreateStart(CoupledProblem,Err)
  CALL CMISSProblemSolverGet(CoupledProblem,CMISSControlLoopNode,1,CoupledSolver,Err)
  !CALL CMISSSolverOutputTypeSet(CoupledSolver,CMISSSolverNoOutput,Err)
  !CALL CMISSSolverOutputTypeSet(CoupledSolver,CMISSSolverProgressOutput,Err)
  !CALL CMISSSolverOutputTypeSet(CoupledSolver,CMISSSolverTimingOutput,Err)
  !CALL CMISSSolverOutputTypeSet(CoupledSolver,CMISSSolverSolverOutput,Err)
  CALL CMISSSolverOutputTypeSet(CoupledSolver,CMISSSolverSolverMatrixOutput,Err)
  CALL CMISSSolverLinearTypeSet(CoupledSolver,CMISSSolverLinearDirectSolveType,Err)
  CALL CMISSSolverLibraryTypeSet(CoupledSolver,CMISSSolverMUMPSLibrary,Err)
  !Finish the creation of the problem solver
  CALL CMISSProblemSolversCreateFinish(CoupledProblem,Err)

  !Start the creation of the problem solver equations for the coupled problem
  PRINT *, ' == >> CREATING PROBLEM SOLVER EQUATIONS << == '
  CALL CMISSSolverTypeInitialise(CoupledSolver,Err)
  CALL CMISSSolverEquationsTypeInitialise(CoupledSolverEquations,Err)
  CALL CMISSProblemSolverEquationsCreateStart(CoupledProblem,Err)
  !Get the solve equations
  CALL CMISSProblemSolverGet(CoupledProblem,CMISSControlLoopNode,1,CoupledSolver,Err)
  CALL CMISSSolverSolverEquationsGet(CoupledSolver,CoupledSolverEquations,Err)
  !Set the solver equations sparsity
  CALL CMISSSolverEquationsSparsityTypeSet(CoupledSolverEquations,CMISSSolverEquationsSparseMatrices,Err)
  !CALL CMISSSolverEquationsSparsityTypeSet(CoupledSolverEquations,CMISSSolverEquationsFullMatrices,Err)  
  !Add in the first equations set
  CALL CMISSSolverEquationsEquationsSetAdd(CoupledSolverEquations,EquationsSet1,EquationsSet1Index,Err)
  !Add in the second equations set
  CALL CMISSSolverEquationsEquationsSetAdd(CoupledSolverEquations,EquationsSet2,EquationsSet2Index,Err)
  !Add in the interface condition
  CALL CMISSSolverEquationsInterfaceConditionAdd(CoupledSolverEquations,InterfaceCondition,InterfaceConditionIndex,Err)
  !Finish the creation of the problem solver equations
  CALL CMISSProblemSolverEquationsCreateFinish(CoupledProblem,Err)

  !Solve the problem
  PRINT *, ' == >> SOLVING PROBLEM << == '
  CALL CMISSProblemSolve(CoupledProblem,Err)

  !Export the fields
  PRINT *, ' == >> EXPORTING FIELDS << == '
  CALL CMISSFieldsTypeInitialise(Fields1,Err)
  CALL CMISSFieldsTypeCreate(Region1,Fields1,Err)
  CALL CMISSFieldIONodesExport(Fields1,"CoupledLaplace_1","FORTRAN",Err)
  CALL CMISSFieldIOElementsExport(Fields1,"CoupledLaplace_1","FORTRAN",Err)
  CALL CMISSFieldsTypeFinalise(Fields1,Err)
  CALL CMISSFieldsTypeInitialise(Fields2,Err)
  CALL CMISSFieldsTypeCreate(Region2,Fields2,Err)
  CALL CMISSFieldIONodesExport(Fields2,"CoupledLaplace_2","FORTRAN",Err)
  CALL CMISSFieldIOElementsExport(Fields2,"CoupledLaplace_2","FORTRAN",Err)
  CALL CMISSFieldsTypeFinalise(Fields2,Err)
  CALL CMISSFieldsTypeInitialise(InterfaceFields,Err)
  CALL CMISSFieldsTypeCreate(INTERFACE,InterfaceFields,Err)
  CALL CMISSFieldIONodesExport(InterfaceFields,"CoupledLaplace_Interface","FORTRAN",Err)
  CALL CMISSFieldIOElementsExport(InterfaceFields,"CoupledLaplace_Interface","FORTRAN",Err)
  CALL CMISSFieldsTypeFinalise(InterfaceFields,Err)
  
  !Finialise CMISS
  CALL CMISSFinalise(Err)

  WRITE(*,'(A)') "Program successfully completed."

  STOP
 
CONTAINS

  SUBROUTINE HANDLE_ERROR(ERROR_STRING)

    CHARACTER(LEN=*), INTENT(IN) :: ERROR_STRING

    WRITE(*,'(">>ERROR: ",A)') ERROR_STRING(1:LEN_TRIM(ERROR_STRING))
    STOP

  END SUBROUTINE HANDLE_ERROR
     
END PROGRAM COUPLEDLAPLACE
