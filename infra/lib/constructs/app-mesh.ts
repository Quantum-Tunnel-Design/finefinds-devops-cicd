import * as cdk from 'aws-cdk-lib';
import * as appmesh from 'aws-cdk-lib/aws-appmesh';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as servicediscovery from 'aws-cdk-lib/aws-servicediscovery';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface AppMeshConstructProps {
  environment: string;
  config: BaseConfig;
  vpc: ec2.IVpc;
  cluster: ecs.ICluster;
}

export class AppMeshConstruct extends Construct {
  public readonly mesh: appmesh.Mesh;
  public readonly virtualNode: appmesh.VirtualNode;
  public readonly virtualService: appmesh.VirtualService;
  public readonly virtualRouter: appmesh.VirtualRouter;

  constructor(scope: Construct, id: string, props: AppMeshConstructProps) {
    super(scope, id);

    // Create App Mesh
    this.mesh = new appmesh.Mesh(this, 'Mesh', {
      meshName: `finefinds-${props.environment}-mesh`,
      egressFilter: appmesh.MeshFilterType.ALLOW_ALL,
    });

    // Create namespace for service discovery
    const namespace = new servicediscovery.PrivateDnsNamespace(this, 'Namespace', {
      vpc: props.vpc,
      name: `finefinds.${props.environment}.local`,
    });

    // Create virtual node for the service
    this.virtualNode = new appmesh.VirtualNode(this, 'VirtualNode', {
      mesh: this.mesh,
      virtualNodeName: `finefinds-${props.environment}-node`,
      serviceDiscovery: appmesh.ServiceDiscovery.dns(`finefinds.${props.environment}.local`),
      listeners: [
        appmesh.VirtualNodeListener.http({
          port: props.config.ecs.containerPort,
          healthCheck: appmesh.HealthCheck.http({
            path: '/health',
            interval: cdk.Duration.seconds(5),
            timeout: cdk.Duration.seconds(2),
            healthyThreshold: 2,
            unhealthyThreshold: 3,
          }),
        }),
      ],
      accessLog: appmesh.AccessLog.fromFilePath('/dev/stdout'),
    });

    // Create virtual router
    this.virtualRouter = new appmesh.VirtualRouter(this, 'VirtualRouter', {
      mesh: this.mesh,
      virtualRouterName: `finefinds-${props.environment}-router`,
      listeners: [
        appmesh.VirtualRouterListener.http(props.config.ecs.containerPort),
      ],
    });

    // Create virtual service
    this.virtualService = new appmesh.VirtualService(this, 'VirtualService', {
      virtualServiceProvider: appmesh.VirtualServiceProvider.virtualRouter(this.virtualRouter),
      virtualServiceName: `finefinds.${props.environment}.local`,
    });

    // Add route to virtual router
    this.virtualRouter.addRoute('Route', {
      routeName: `finefinds-${props.environment}-route`,
      routeSpec: appmesh.RouteSpec.http({
        weightedTargets: [
          {
            virtualNode: this.virtualNode,
            weight: 1,
          },
        ],
        match: {
          path: appmesh.HttpRoutePathMatch.startsWith('/'),
        },
      }),
    });

    // Output mesh name
    new cdk.CfnOutput(this, 'MeshName', {
      value: this.mesh.meshName,
      description: 'App Mesh name',
      exportName: `finefinds-${props.environment}-mesh-name`,
    });
  }
} 