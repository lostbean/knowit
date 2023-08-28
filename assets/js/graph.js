import cytoscape from "cytoscape"
import { setupDragAndDrop } from "./graph/dragAndDrop" 

export const Graph = {
    mounted() {
        var ctx = this.el;
        var cy = cytoscape({
            container: ctx,

            boxSelectionEnabled: false,

            style: [
                {
                    selector: 'node',
                    style: {
                        'label': (node) => {
                            const name = node.data('name') || node.data('edge') || node.data('id');
                            return node.data('object_base') === true ? '' : name;
                        },
                        'shape': (node) => node.data('object_base') === true ? 'round-rectangle' : 'ellipse',
                        'background-color': (node) => {
                            if (node.isChild) {
                                const parent = node.parent();
                                const color = parent.style('background-color');
                                return '#60A5FA' // TODO
                            } else {
                                return '#A8A29E';
                            }
                        },
                        'border-color': '#78716C',
                        'border-width': '1px',
                        'text-outline-color': '#FFF',
                        'text-outline-opacity': 0.9,
                        'text-outline-width': 2,
                        'font-size': 11,
                        'text-valign': 'center',
                        'text-halign': 'center'
                    }
                },
                {
                    selector: ':parent',
                    style: {
                        'label': (node) => node.data('name') || node.data('id'),
                        'background-color': (node) => node.data('color') || 'gray',
                        'shape': 'round-rectangle',
                        'background-opacity': 0.5,
                        'text-valign': 'top',
                        'text-halign': 'center',
                    }
                },
                {
                    selector: 'edge',
                    style: {
                        'label': (edge) => edge.data('type') || edge.data('id'),
                        "line-style": (edge) => {
                            const edgeType = edge.data('name');
                            return (edgeType == 'inference_link') ? 'dashed' : 'solid'
                        },
                        'text-rotation': 'autorotate',
                        'text-outline-color': '#FFF',
                        'text-outline-opacity': 0.9,
                        'text-outline-width': 2,
                        "text-margin-x": "0px",
                        "text-margin-y": "0px",
                        'font-size': 11,
                        'curve-style': 'bezier',
                        'target-arrow-shape': 'triangle'
                    }
                }
            ],

            layout: {
                name: 'cose',
                padding: 5
            }
        });

        setupDragAndDrop(cy);

        const cose_layout = {
            nodeOverlap: 5,
            componentSpacing: 80,
            padding: 50,
            name: 'cose',
            fit: true
        };


        this.handleEvent("add_points", ({ points }) => {
            console.log(points);
            cy.add(points);
            cy.layout(cose_layout).run();
            cy.fit();
        });
        
        this.handleEvent("reset_points", ({ points }) => {
            cy.remove('*');
            console.log(points);
            cy.add(points);
            cy.layout(cose_layout).run();
            cy.fit();
        });

    }
}