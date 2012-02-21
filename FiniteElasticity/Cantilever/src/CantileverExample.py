#!/usr/bin/env python

#> \file
#> \author Chris Bradley
#> \brief This is an example script to solve a finite elasticity equation using openCMISS calls in python.
#>
#> \section LICENSE
#>
#> Version: MPL 1.1/GPL 2.0/LGPL 2.1
#>
#> The contents of this file are subject to the Mozilla Public License
#> Version 1.1 (the "License"); you may not use this file except in
#> compliance with the License. You may obtain a copy of the License at
#> http://www.mozilla.org/MPL/
#>
#> Software distributed under the License is distributed on an "AS IS"
#> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
#> License for the specific language governing rights and limitations
#> under the License.
#>
#> The Original Code is openCMISS
#>
#> The Initial Developer of the Original Code is University of Auckland,
#> Auckland, New Zealand and University of Oxford, Oxford, United
#> Kingdom. Portions created by the University of Auckland and University
#> of Oxford are Copyright (C) 2007 by the University of Auckland and
#> the University of Oxford. All Rights Reserved.
#>
#> Contributor(s): 
#>
#> Alternatively, the contents of this file may be used under the terms of
#> either the GNU General Public License Version 2 or later (the "GPL"), or
#> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
#> in which case the provisions of the GPL or the LGPL are applicable instead
#> of those above. if you wish to allow use of your version of this file only
#> under the terms of either the GPL or the LGPL, and not to allow others to
#> use your version of this file under the terms of the MPL, indicate your
#> decision by deleting the provisions above and replace them with the notice
#> and other provisions required by the GPL or the LGPL. if you do not delete
#> the provisions above, a recipient may use your version of this file under
#> the terms of any one of the MPL, the GPL or the LGPL.
#>

#> \example FiniteElasticity/Cantilever/src/CantileverExample.py
## Example script to solve a finite elasticity equation using openCMISS calls in python.
## \par Latest Builds:
## \li <a href='http://autotest.bioeng.auckland.ac.nz/opencmiss-build/logs_x86_64-linux/FiniteElasticity/Cantilever/build-intel'>Linux Intel Build</a>
## \li <a href='http://autotest.bioeng.auckland.ac.nz/opencmiss-build/logs_x86_64-linux/FiniteElasticity/Cantilever/build-gnu'>Linux GNU Build</a>
#<

#> Main script
# Add Python bindings directory to PATH
import sys, os

sys.path.append(os.sep.join((os.environ['OPENCMISS_ROOT'],'cm','bindings','python')))

# Intialise OpenCMISS
from opencmiss import CMISS

# Set problem parameters

width = 60.0
length = 40.0
height = 40.0
density=9.0E-4 #in g mm^-3
gravity=[0.0,0.0,-9.81] #in m s^-2

UsePressureBasis = False
NumberOfGaussXi = 2

coordinateSystemUserNumber = 1
regionUserNumber = 1
basisUserNumber = 1
pressureBasisUserNumber = 2
generatedMeshUserNumber = 1
meshUserNumber = 1
decompositionUserNumber = 1
geometricFieldUserNumber = 1
fibreFieldUserNumber = 2
materialFieldUserNumber = 3
dependentFieldUserNumber = 4
sourceFieldUserNumber = 5
equationsSetFieldUserNumber = 6
equationsSetUserNumber = 1
problemUserNumber = 1

# Set all diganostic levels on for testing
#CMISS.DiagnosticsSetOn(CMISS.DiagnosticTypes.All,[1,2,3,4,5],"Diagnostics",["DOMAIN_MAPPINGS_LOCAL_FROM_GLOBAL_CALCULATE"])

numberOfLoadIncrements = 2
numberGlobalXElements = 1
numberGlobalYElements = 1
numberGlobalZElements = 1
InterpolationType = 1
if(numberGlobalZElements==0):
    numberOfXi = 2
else:
    numberOfXi = 3

# Get the number of computational nodes and this computational node number
numberOfComputationalNodes = CMISS.ComputationalNumberOfNodesGet()
computationalNodeNumber = CMISS.ComputationalNodeNumberGet()

# Create a 3D rectangular cartesian coordinate system
coordinateSystem = CMISS.CoordinateSystem()
coordinateSystem.CreateStart(coordinateSystemUserNumber)
coordinateSystem.DimensionSet(3)
coordinateSystem.CreateFinish()

# Create a region and assign the coordinate system to the region
region = CMISS.Region()
region.CreateStart(regionUserNumber,CMISS.WorldRegion)
#region.LabelSet("Region")
region.coordinateSystem = coordinateSystem
region.CreateFinish()

# Define basis
basis = CMISS.Basis()
basis.CreateStart(basisUserNumber)
if InterpolationType in (1,2,3,4):
    basis.type = CMISS.BasisTypes.LAGRANGE_HERMITE_TP
elif InterpolationType in (7,8,9):
    basis.type = CMISS.BasisTypes.SIMPLEX
basis.numberOfXi = numberOfXi
basis.interpolationXi = [CMISS.BasisInterpolationSpecifications.LINEAR_LAGRANGE]*numberOfXi
if(NumberOfGaussXi>0):
    basis.quadratureNumberOfGaussXi = [NumberOfGaussXi]*numberOfXi
basis.CreateFinish()

if(UsePressureBasis):
    # Define pressure basis
    pressureBasis = CMISS.Basis()
    pressureBasis.CreateStart(pressureBasisUserNumber)
    if InterpolationType in (1,2,3,4):
        pressureBasis.type = CMISS.BasisTypes.LAGRANGE_HERMITE_TP
    elif InterpolationType in (7,8,9):
        pressureBasis.type = CMISS.BasisTypes.SIMPLEX
    pressureBasis.numberOfXi = numberOfXi
    pressureBasis.interpolationXi = [CMISS.BasisInterpolationSpecifications.LINEAR_LAGRANGE]*numberOfXi
    if(NumberOfGaussXi>0):
        pressureBasis.quadratureNumberOfGaussXi = [NumberOfGaussXi]*numberOfXi
    pressureBasis.CreateFinish()

# Start the creation of a generated mesh in the region
generatedMesh = CMISS.GeneratedMesh()
generatedMesh.CreateStart(generatedMeshUserNumber,region)
generatedMesh.type = CMISS.GeneratedMeshTypes.REGULAR
if(UsePressureBasis):
    generatedMesh.basis = [basis,pressureBasis]
else:
    generatedMesh.basis = [basis]
if(numberGlobalZElements==0):
    generatedMesh.extent = [width,height]
    generatedMesh.numberOfElements = [numberGlobalXElements,numberGlobalYElements]
else:
    generatedMesh.extent = [width,length,height]
    generatedMesh.numberOfElements = [numberGlobalXElements,numberGlobalYElements,numberGlobalZElements]
# Finish the creation of a generated mesh in the region
mesh = CMISS.Mesh()
generatedMesh.CreateFinish(meshUserNumber,mesh)

# Create a decomposition for the mesh
decomposition = CMISS.Decomposition()
decomposition.CreateStart(decompositionUserNumber,mesh)
decomposition.type = CMISS.DecompositionTypes.CALCULATED
decomposition.numberOfDomains = numberOfComputationalNodes
decomposition.CreateFinish()

# Create a field for the geometry
geometricField = CMISS.Field()
geometricField.CreateStart(geometricFieldUserNumber,region)
geometricField.MeshDecompositionSet(decomposition)
geometricField.TypeSet(CMISS.FieldTypes.GEOMETRIC)
geometricField.VariableLabelSet(CMISS.FieldVariableTypes.U,"Geometry")
geometricField.ComponentMeshComponentSet(CMISS.FieldVariableTypes.U,1,1)
geometricField.ComponentMeshComponentSet(CMISS.FieldVariableTypes.U,2,1)
geometricField.ComponentMeshComponentSet(CMISS.FieldVariableTypes.U,3,1)
if InterpolationType == 4:
    geometricField.fieldScalingType = CMISS.FieldScalingTypes.ARITHMETIC_MEAN
geometricField.CreateFinish()

# Update the geometric field parameters from generated mesh
generatedMesh.GeometricParametersCalculate(geometricField)

# Create a fibre field and attach it to the geometric field
fibreField = CMISS.Field()
fibreField.CreateStart(fibreFieldUserNumber,region)
fibreField.TypeSet(CMISS.FieldTypes.FIBRE)
fibreField.MeshDecompositionSet(decomposition)
fibreField.GeometricFieldSet(geometricField)
fibreField.VariableLabelSet(CMISS.FieldVariableTypes.U,"Fibre")
if InterpolationType == 4:
    fibreField.fieldScalingType = CMISS.FieldScalingTypes.ARITHMETIC_MEAN
fibreField.CreateFinish()

# Create the equations_set
equationsSetField = CMISS.Field()
equationsSet = CMISS.EquationsSet()
equationsSet.CreateStart(equationsSetUserNumber,region,fibreField,
    CMISS.EquationsSetClasses.ELASTICITY,
    CMISS.EquationsSetTypes.FINITE_ELASTICITY,
    CMISS.EquationsSetSubtypes.MOONEY_RIVLIN,
    equationsSetFieldUserNumber, equationsSetField)
equationsSet.CreateFinish()

# Create the dependent field
dependentField = CMISS.Field()
equationsSet.DependentCreateStart(dependentFieldUserNumber,dependentField)
dependentField.VariableLabelSet(CMISS.FieldVariableTypes.U,"Dependent")
dependentField.ComponentInterpolationSet(CMISS.FieldVariableTypes.U,4,CMISS.FieldInterpolationTypes.ELEMENT_BASED)
dependentField.ComponentInterpolationSet(CMISS.FieldVariableTypes.DELUDELN,4,CMISS.FieldInterpolationTypes.ELEMENT_BASED)
if(UsePressureBasis):
    # Set the pressure to be nodally based and use the second mesh component
    if InterpolationType == 4:
        dependentField.ComponentInterpolationSet(CMISS.FieldVariableTypes.U,4,CMISS.FieldInterpolationTypes.NODE_BASED)
        dependentField.ComponentInterpolationSet(CMISS.FieldVariableTypes.DELUDELN,4,CMISS.FieldInterpolationTypes.NODE_BASED)
    dependentField.ComponentMeshComponentSet(CMISS.FieldVariableTypes.U,4,2)
    dependentField.ComponentMeshComponentSet(CMISS.FieldVariableTypes.DELUDELN,4,2)
if InterpolationType == 4:
    dependentField.fieldScalingType = CMISS.FieldScalingTypes.ARITHMETIC_MEAN
equationsSet.DependentCreateFinish()


# Initialise dependent field from undeformed geometry and displacement bcs and set hydrostatic pressure
CMISS.Field.ParametersToFieldParametersComponentCopy(
    geometricField,CMISS.FieldVariableTypes.U,CMISS.FieldParameterSetTypes.VALUES,1,
    dependentField,CMISS.FieldVariableTypes.U,CMISS.FieldParameterSetTypes.VALUES,1)
CMISS.Field.ParametersToFieldParametersComponentCopy(
    geometricField,CMISS.FieldVariableTypes.U,CMISS.FieldParameterSetTypes.VALUES,2,
    dependentField,CMISS.FieldVariableTypes.U,CMISS.FieldParameterSetTypes.VALUES,2)
CMISS.Field.ParametersToFieldParametersComponentCopy(
    geometricField,CMISS.FieldVariableTypes.U,CMISS.FieldParameterSetTypes.VALUES,3,
    dependentField,CMISS.FieldVariableTypes.U,CMISS.FieldParameterSetTypes.VALUES,3)
CMISS.Field.ComponentValuesInitialiseDP(
    dependentField,CMISS.FieldVariableTypes.U,CMISS.FieldParameterSetTypes.VALUES,4,-8.0)

# Create the material field
materialField = CMISS.Field()
equationsSet.MaterialsCreateStart(materialFieldUserNumber,materialField)
materialField.VariableLabelSet(CMISS.FieldVariableTypes.U,"Material")
materialField.VariableLabelSet(CMISS.FieldVariableTypes.V,"Density")
equationsSet.MaterialsCreateFinish()

# Set Mooney-Rivlin constants c10 and c01 respectively.
materialField.ComponentValuesInitialiseDP(
    CMISS.FieldVariableTypes.U,CMISS.FieldParameterSetTypes.VALUES,1,2.0)
materialField.ComponentValuesInitialiseDP(
    CMISS.FieldVariableTypes.U,CMISS.FieldParameterSetTypes.VALUES,2,2.0)
materialField.ComponentValuesInitialiseDP(
    CMISS.FieldVariableTypes.V,CMISS.FieldParameterSetTypes.VALUES,1,density)

#Create the source field with the gravity vector
sourceField = CMISS.Field()
equationsSet.SourceCreateStart(sourceFieldUserNumber,sourceField)
sourceField.fieldScalingType = CMISS.FieldScalingTypes.ARITHMETIC_MEAN
if InterpolationType == 4:
    sourceField.fieldScalingType = CMISS.FieldScalingTypes.ARITHMETIC_MEAN
else:
    sourceField.fieldScalingType = CMISS.FieldScalingTypes.UNIT
equationsSet.SourceCreateFinish()

#Set the gravity vector component values
sourceField.ComponentValuesInitialiseDP(
    CMISS.FieldVariableTypes.U,CMISS.FieldParameterSetTypes.VALUES,1,gravity[0])
sourceField.ComponentValuesInitialiseDP(
    CMISS.FieldVariableTypes.U,CMISS.FieldParameterSetTypes.VALUES,2,gravity[1])
sourceField.ComponentValuesInitialiseDP(
    CMISS.FieldVariableTypes.U,CMISS.FieldParameterSetTypes.VALUES,3,gravity[2])

# Create equations
equations = CMISS.Equations()
equationsSet.EquationsCreateStart(equations)
equations.sparsityType = CMISS.EquationsSparsityTypes.SPARSE
equations.outputType = CMISS.EquationsOutputTypes.NONE
equationsSet.EquationsCreateFinish()

# Define the problem
problem = CMISS.Problem()
problem.CreateStart(problemUserNumber)
problem.SpecificationSet(CMISS.ProblemClasses.ELASTICITY,
        CMISS.ProblemTypes.FINITE_ELASTICITY,
        CMISS.ProblemSubTypes.NONE)
problem.CreateFinish()

# Create the problem control loop
problem.ControlLoopCreateStart()
controlLoop = CMISS.ControlLoop()
problem.ControlLoopGet([CMISS.ControlLoopIdentifiers.NODE],controlLoop)
controlLoop.MaximumIterationsSet(numberOfLoadIncrements)
problem.ControlLoopCreateFinish()

# Create problem solver
nonLinearSolver = CMISS.Solver()
linearSolver = CMISS.Solver()
problem.SolversCreateStart()
problem.SolverGet([CMISS.ControlLoopIdentifiers.NODE],1,nonLinearSolver)
nonLinearSolver.outputType = CMISS.SolverOutputTypes.PROGRESS
nonLinearSolver.NewtonJacobianCalculationTypeSet(CMISS.JacobianCalculationTypes.EQUATIONS)
nonLinearSolver.NewtonLinearSolverGet(linearSolver)
linearSolver.linearType = CMISS.LinearSolverTypes.DIRECT
#linearSolver.libraryType = CMISS.SolverLibraries.LAPACK
problem.SolversCreateFinish()

# Create solver equations and add equations set to solver equations
solver = CMISS.Solver()
solverEquations = CMISS.SolverEquations()
problem.SolverEquationsCreateStart()
problem.SolverGet([CMISS.ControlLoopIdentifiers.NODE],1,solver)
solver.SolverEquationsGet(solverEquations)
solverEquations.sparsityType = CMISS.SolverEquationsSparsityTypes.SPARSE
equationsSetIndex = solverEquations.EquationsSetAdd(equationsSet)
problem.SolverEquationsCreateFinish()

# Prescribe boundary conditions (absolute nodal parameters)
boundaryConditions = CMISS.BoundaryConditions()
solverEquations.BoundaryConditionsCreateStart(boundaryConditions)
# Set x=0 nodes to no x displacment
boundaryConditions.AddNode(dependentField,CMISS.FieldVariableTypes.U,1,1,1,1,CMISS.BoundaryConditionsTypes.FIXED,0.0)
boundaryConditions.AddNode(dependentField,CMISS.FieldVariableTypes.U,1,1,3,1,CMISS.BoundaryConditionsTypes.FIXED,0.0)
boundaryConditions.AddNode(dependentField,CMISS.FieldVariableTypes.U,1,1,5,1,CMISS.BoundaryConditionsTypes.FIXED,0.0)
boundaryConditions.AddNode(dependentField,CMISS.FieldVariableTypes.U,1,1,7,1,CMISS.BoundaryConditionsTypes.FIXED,0.0)

# Set y=0 nodes to no y displacement
boundaryConditions.AddNode(dependentField,CMISS.FieldVariableTypes.U,1,1,1,2,CMISS.BoundaryConditionsTypes.FIXED,0.0)
boundaryConditions.AddNode(dependentField,CMISS.FieldVariableTypes.U,1,1,3,2,CMISS.BoundaryConditionsTypes.FIXED,0.0)
boundaryConditions.AddNode(dependentField,CMISS.FieldVariableTypes.U,1,1,5,2,CMISS.BoundaryConditionsTypes.FIXED,0.0)
boundaryConditions.AddNode(dependentField,CMISS.FieldVariableTypes.U,1,1,7,2,CMISS.BoundaryConditionsTypes.FIXED,0.0)

# Set z=0 nodes to no y displacement
boundaryConditions.AddNode(dependentField,CMISS.FieldVariableTypes.U,1,1,1,3,CMISS.BoundaryConditionsTypes.FIXED,0.0)
boundaryConditions.AddNode(dependentField,CMISS.FieldVariableTypes.U,1,1,3,3,CMISS.BoundaryConditionsTypes.FIXED,0.0)
boundaryConditions.AddNode(dependentField,CMISS.FieldVariableTypes.U,1,1,5,3,CMISS.BoundaryConditionsTypes.FIXED,0.0)
boundaryConditions.AddNode(dependentField,CMISS.FieldVariableTypes.U,1,1,7,3,CMISS.BoundaryConditionsTypes.FIXED,0.0)
solverEquations.BoundaryConditionsCreateFinish()

# Solve the problem
problem.Solve()

# Export results
fields = CMISS.Fields()
CMISS.Fields.CreateRegion(fields,region)
CMISS.Fields.NodesExport(fields,"../Cantilever","FORTRAN")
CMISS.Fields.ElementsExport(fields,"../Cantilever","FORTRAN")
fields.Finalise()

